alter table public.round_events
	add column if not exists mode text check (mode in ('wins', 'loses')),
	add column if not exists selected_player_id uuid references public.game_players (id) on delete set null,
	add column if not exists spritz boolean not null default false;

create table public.round_bummerl_awards (
	round_id uuid not null references public.rounds (id) on delete cascade,
	event_id uuid not null references public.round_events (id) on delete cascade,
	player_id uuid not null references public.game_players (id) on delete cascade,
	primary key (round_id, player_id),
	unique (event_id, player_id)
);

alter table public.round_bummerl_awards enable row level security;

create policy "Users can view Bummerl awards in their own rounds"
on public.round_bummerl_awards for select
using (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_bummerl_awards.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can create Bummerl awards in their own rounds"
on public.round_bummerl_awards for insert
with check (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_bummerl_awards.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can delete Bummerl awards in their own rounds"
on public.round_bummerl_awards for delete
using (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_bummerl_awards.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can delete events in their own rounds"
on public.round_events for delete
using (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_events.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can delete rounds in their own games"
on public.rounds for delete
using (
	exists (
		select 1 from public.games
		where games.id = rounds.game_id
		and games.owner_id = (select auth.uid())
	)
);

drop function if exists public.apply_score_event(uuid, text, integer, uuid[]);

create or replace function public.apply_score_event(
	p_round_id uuid,
	p_title text,
	p_points integer,
	p_selected_player_id uuid,
	p_mode text,
	p_spritz boolean default false
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
	game_id_for_round uuid;
	event_id uuid;
	winner_id uuid;
	loser_ids uuid[];
	target_ids uuid[];
	highest_remaining integer;
	next_round_id uuid;
	next_round_number integer;
	starting_points_for_game integer;
	effective_points integer;
	event_title text;
begin
	if auth.uid() is null then
		raise exception 'not authenticated';
	end if;
	if p_points is null or p_points >= 0 then
		raise exception 'score events must subtract points';
	end if;
	if char_length(btrim(coalesce(p_title, ''))) not between 1 and 80 then
		raise exception 'event title is invalid';
	end if;
	if p_mode not in ('wins', 'loses') then
		raise exception 'score mode is invalid';
	end if;

	select rounds.game_id, games.starting_points
	into game_id_for_round, starting_points_for_game
	from public.rounds
	join public.games on games.id = rounds.game_id
	where rounds.id = p_round_id
	and rounds.status = 'active'
	and games.owner_id = auth.uid();

	if not found then
		raise exception 'active round not found';
	end if;

	if not exists (
		select 1 from public.game_players
		where id = p_selected_player_id and game_id = game_id_for_round
	) then
		raise exception 'selected player does not belong to this game';
	end if;

	effective_points := p_points * case when p_spritz then 2 else 1 end;
	event_title := btrim(p_title) || case when p_spritz then ' (Gspritzt)' else '' end;

	select array_agg(game_players.id order by game_players.player_order)
	into target_ids
	from public.game_players
	where game_id = game_id_for_round
	and (
		(p_mode = 'wins' and id = p_selected_player_id)
		or (p_mode = 'loses' and id <> p_selected_player_id)
	);

	insert into public.round_events (round_id, title, points, mode, selected_player_id, spritz)
	values (p_round_id, event_title, effective_points, p_mode, p_selected_player_id, p_spritz)
	returning id into event_id;

	insert into public.round_event_players (event_id, player_id)
	select event_id, player_id
	from unnest(target_ids) as player_id;

	update public.round_player_scores
	set remaining_points = remaining_points + effective_points
	where round_id = p_round_id
	and player_id = any(target_ids);

	select round_player_scores.player_id
	into winner_id
	from public.round_player_scores
	join public.game_players on game_players.id = round_player_scores.player_id
	where round_player_scores.round_id = p_round_id
	and round_player_scores.remaining_points <= 0
	order by game_players.player_order
	limit 1;

	if winner_id is not null then
		select max(remaining_points)
		into highest_remaining
		from public.round_player_scores
		where round_id = p_round_id
		and player_id <> winner_id;

		select array_agg(player_id)
		into loser_ids
		from public.round_player_scores
		where round_id = p_round_id
		and player_id <> winner_id
		and remaining_points = highest_remaining;

		insert into public.round_bummerl_awards (round_id, event_id, player_id)
		select p_round_id, event_id, player_id
		from unnest(loser_ids) as player_id;

		update public.game_players
		set bummerl_count = bummerl_count + 1
		where id = any(loser_ids);

		update public.rounds
		set status = 'completed',
			winner_player_id = winner_id,
			completed_at = timezone('utc', now())
		where id = p_round_id;

		select coalesce(max(round_number), 0) + 1
		into next_round_number
		from public.rounds
		where game_id = game_id_for_round;

		insert into public.rounds (game_id, round_number, starting_points)
		values (game_id_for_round, next_round_number, starting_points_for_game)
		returning id into next_round_id;

		insert into public.round_player_scores (round_id, player_id, remaining_points)
		select next_round_id, id, starting_points_for_game
		from public.game_players
		where game_id = game_id_for_round;
	end if;

	update public.games
	set last_event_at = timezone('utc', now())
	where id = game_id_for_round;

	return jsonb_build_object(
		'round_completed', winner_id is not null,
		'winner_player_id', winner_id,
		'loser_player_ids', coalesce(loser_ids, array[]::uuid[]),
		'next_round_id', next_round_id
	);
end;
$$;

revoke all on function public.apply_score_event(uuid, text, integer, uuid, text, boolean) from public;
grant execute on function public.apply_score_event(uuid, text, integer, uuid, text, boolean) to authenticated;

create or replace function public.undo_last_score_event(p_game_id uuid)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
	last_event_id uuid;
	last_round_id uuid;
	last_event_points integer;
	last_round_status text;
	active_round_id uuid;
	previous_event_at timestamptz;
	award_player_id uuid;
begin
	if auth.uid() is null then
		raise exception 'not authenticated';
	end if;

	if not exists (select 1 from public.games where id = p_game_id and owner_id = auth.uid()) then
		raise exception 'game not found';
	end if;

	select round_events.id, round_events.round_id, round_events.points, rounds.status
	into last_event_id, last_round_id, last_event_points, last_round_status
	from public.round_events
	join public.rounds on rounds.id = round_events.round_id
	where rounds.game_id = p_game_id
	order by round_events.created_at desc, round_events.id desc
	limit 1;

	if not found then
		raise exception 'no score event to undo';
	end if;

	if last_round_status = 'completed' then
		select id
		into active_round_id
		from public.rounds
		where game_id = p_game_id
		and status = 'active'
		and round_number = (select round_number + 1 from public.rounds where id = last_round_id)
		and not exists (select 1 from public.round_events where round_id = rounds.id);

		if active_round_id is null then
			raise exception 'the completed round cannot be undone after the next round has started';
		end if;

		delete from public.rounds where id = active_round_id;
		update public.rounds
		set status = 'active', winner_player_id = null, completed_at = null
		where id = last_round_id;

		for award_player_id in
			select player_id from public.round_bummerl_awards where event_id = last_event_id
		loop
			update public.game_players
			set bummerl_count = greatest(0, bummerl_count - 1)
			where id = award_player_id;
		end loop;

		delete from public.round_bummerl_awards where event_id = last_event_id;
	end if;

	update public.round_player_scores
	set remaining_points = remaining_points - last_event_points
	where round_id = last_round_id
	and player_id in (select player_id from public.round_event_players where event_id = last_event_id);

	delete from public.round_events where id = last_event_id;

	select max(round_events.created_at)
	into previous_event_at
	from public.round_events
	join public.rounds on rounds.id = round_events.round_id
	where rounds.game_id = p_game_id;

	update public.games
	set last_event_at = coalesce(previous_event_at, started_at)
	where id = p_game_id;

	return jsonb_build_object('undone_event_id', last_event_id, 'round_reopened', last_round_status = 'completed');
end;
$$;

revoke all on function public.undo_last_score_event(uuid) from public;
grant execute on function public.undo_last_score_event(uuid) to authenticated;
