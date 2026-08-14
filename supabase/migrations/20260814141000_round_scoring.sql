create table public.rounds (
	id uuid primary key default gen_random_uuid(),
	game_id uuid not null references public.games (id) on delete cascade,
	round_number integer not null check (round_number > 0),
	starting_points integer not null check (starting_points > 0),
	status text not null default 'active' check (status in ('active', 'completed')),
	winner_player_id uuid references public.game_players (id) on delete set null,
	started_at timestamptz not null default timezone('utc', now()),
	completed_at timestamptz,
	unique (game_id, round_number)
);

create unique index rounds_one_active_per_game_idx
	on public.rounds (game_id)
	where status = 'active';

create table public.round_player_scores (
	round_id uuid not null references public.rounds (id) on delete cascade,
	player_id uuid not null references public.game_players (id) on delete cascade,
	remaining_points integer not null,
	primary key (round_id, player_id)
);

create table public.round_events (
	id uuid primary key default gen_random_uuid(),
	round_id uuid not null references public.rounds (id) on delete cascade,
	title text not null check (char_length(btrim(title)) between 1 and 80),
	points integer not null check (points < 0),
	created_at timestamptz not null default timezone('utc', now())
);

create table public.round_event_players (
	event_id uuid not null references public.round_events (id) on delete cascade,
	player_id uuid not null references public.game_players (id) on delete cascade,
	primary key (event_id, player_id)
);

create index round_events_round_idx on public.round_events (round_id, created_at);
create index round_event_players_event_idx on public.round_event_players (event_id);

alter table public.rounds enable row level security;
alter table public.round_player_scores enable row level security;
alter table public.round_events enable row level security;
alter table public.round_event_players enable row level security;

create policy "Users can view rounds in their own games"
on public.rounds for select
using (
	exists (
		select 1 from public.games
		where games.id = rounds.game_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can create rounds in their own games"
on public.rounds for insert
with check (
	exists (
		select 1 from public.games
		where games.id = rounds.game_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can update rounds in their own games"
on public.rounds for update
using (
	exists (
		select 1 from public.games
		where games.id = rounds.game_id
		and games.owner_id = (select auth.uid())
	)
)
with check (
	exists (
		select 1 from public.games
		where games.id = rounds.game_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can view scores in their own rounds"
on public.round_player_scores for select
using (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_player_scores.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can create scores in their own rounds"
on public.round_player_scores for insert
with check (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_player_scores.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can update scores in their own rounds"
on public.round_player_scores for update
using (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_player_scores.round_id
		and games.owner_id = (select auth.uid())
	)
)
with check (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_player_scores.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can view events in their own rounds"
on public.round_events for select
using (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_events.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can create events in their own rounds"
on public.round_events for insert
with check (
	exists (
		select 1
		from public.rounds
		join public.games on games.id = rounds.game_id
		where rounds.id = round_events.round_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can view event players in their own rounds"
on public.round_event_players for select
using (
	exists (
		select 1
		from public.round_events
		join public.rounds on rounds.id = round_events.round_id
		join public.games on games.id = rounds.game_id
		where round_events.id = round_event_players.event_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can create event players in their own rounds"
on public.round_event_players for insert
with check (
	exists (
		select 1
		from public.round_events
		join public.rounds on rounds.id = round_events.round_id
		join public.games on games.id = rounds.game_id
		where round_events.id = round_event_players.event_id
		and games.owner_id = (select auth.uid())
	)
);

create or replace function public.start_round(p_game_id uuid)
returns uuid
language plpgsql
set search_path = public
as $$
declare
	new_round_id uuid;
	next_round_number integer;
	game_starting_points integer;
begin
	if auth.uid() is null then
		raise exception 'not authenticated';
	end if;

	select starting_points
	into game_starting_points
	from public.games
	where id = p_game_id and owner_id = auth.uid();

	if not found then
		raise exception 'game not found';
	end if;

	select id
	into new_round_id
	from public.rounds
	where game_id = p_game_id and status = 'active';

	if found then
		return new_round_id;
	end if;

	select coalesce(max(round_number), 0) + 1
	into next_round_number
	from public.rounds
	where game_id = p_game_id;

	insert into public.rounds (game_id, round_number, starting_points)
	values (p_game_id, next_round_number, game_starting_points)
	returning id into new_round_id;

	insert into public.round_player_scores (round_id, player_id, remaining_points)
	select new_round_id, id, game_starting_points
	from public.game_players
	where game_id = p_game_id;

	update public.games
	set last_event_at = timezone('utc', now())
	where id = p_game_id;

	return new_round_id;
end;
$$;

revoke all on function public.start_round(uuid) from public;
grant execute on function public.start_round(uuid) to authenticated;

create or replace function public.apply_score_event(
	p_round_id uuid,
	p_title text,
	p_points integer,
	p_player_ids uuid[]
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

	select array_agg(distinct player_id)
	into target_ids
	from unnest(p_player_ids) as player_id;

	if coalesce(cardinality(target_ids), 0) = 0 then
		raise exception 'select at least one player';
	end if;

	if (
		select count(*)
		from public.round_player_scores
		where round_id = p_round_id
		and player_id = any(target_ids)
	) <> cardinality(target_ids) then
		raise exception 'one or more players do not belong to this round';
	end if;

	insert into public.round_events (round_id, title, points)
	values (p_round_id, btrim(p_title), p_points)
	returning id into event_id;

	insert into public.round_event_players (event_id, player_id)
	select event_id, player_id
	from unnest(target_ids) as player_id;

	update public.round_player_scores
	set remaining_points = remaining_points + p_points
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

revoke all on function public.apply_score_event(uuid, text, integer, uuid[]) from public;
grant execute on function public.apply_score_event(uuid, text, integer, uuid[]) to authenticated;
