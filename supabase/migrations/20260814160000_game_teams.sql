create table public.game_teams (
	id uuid primary key default gen_random_uuid(),
	game_id uuid not null references public.games (id) on delete cascade,
	team_order smallint not null check (team_order between 1 and 4),
	name text not null check (char_length(btrim(name)) between 1 and 80),
	bummerl_count integer not null default 0 check (bummerl_count >= 0),
	unique (game_id, team_order)
);

create index game_teams_game_idx on public.game_teams (game_id, team_order);

alter table public.game_players add column if not exists team_id uuid references public.game_teams (id) on delete cascade;
alter table public.rounds add column if not exists winner_team_id uuid references public.game_teams (id) on delete set null;
alter table public.round_events add column if not exists selected_team_id uuid references public.game_teams (id) on delete set null;
alter table public.round_bummerl_awards add column if not exists team_id uuid references public.game_teams (id) on delete cascade;

insert into public.game_teams (game_id, team_order, name)
select games.id, team_numbers.team_order, 'Team ' || team_numbers.team_order
from public.games
cross join lateral generate_series(1, case when games.player_count = 4 then 2 else games.player_count end) as team_numbers(team_order)
where not exists (
	select 1 from public.game_teams
	where game_teams.game_id = games.id
);

update public.game_players
set team_id = game_teams.id
from public.games
join public.game_teams on game_teams.game_id = games.id
where game_players.game_id = games.id
and game_teams.team_order = case
	when games.player_count = 4 then case when game_players.player_order in (1, 3) then 1 else 2 end
	else game_players.player_order
end;

alter table public.game_players alter column team_id set not null;

alter table public.game_teams enable row level security;

create policy "Users can view teams in their own games"
on public.game_teams for select
using (exists (
	select 1 from public.games
	where games.id = game_teams.game_id
	and games.owner_id = (select auth.uid())
));

create policy "Users can create teams in their own games"
on public.game_teams for insert
with check (exists (
	select 1 from public.games
	where games.id = game_teams.game_id
	and games.owner_id = (select auth.uid())
));

create policy "Users can update teams in their own games"
on public.game_teams for update
using (exists (
	select 1 from public.games
	where games.id = game_teams.game_id
	and games.owner_id = (select auth.uid())
))
with check (exists (
	select 1 from public.games
	where games.id = game_teams.game_id
	and games.owner_id = (select auth.uid())
));

drop function if exists public.create_game(text[], integer);

create or replace function public.create_game(
	p_player_names text[],
	p_starting_points integer,
	p_team_numbers integer[]
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
	new_game_id uuid;
	new_team_id uuid;
	player_index integer;
	team_index integer;
	clean_name text;
	player_total integer;
	team_total integer;
begin
	if auth.uid() is null then
		raise exception 'not authenticated';
	end if;

	player_total := coalesce(cardinality(p_player_names), 0);
	if player_total not between 2 and 4 then
		raise exception 'a game needs between 2 and 4 players';
	end if;
	if cardinality(p_team_numbers) <> player_total then
		raise exception 'every player needs a team';
	end if;
	if p_starting_points is null or p_starting_points <= 0 then
		raise exception 'starting points must be greater than zero';
	end if;

	team_total := case when player_total = 4 then 2 else player_total end;
	for player_index in 1..player_total loop
		if p_team_numbers[player_index] < 1 or p_team_numbers[player_index] > team_total then
			raise exception 'team assignment is invalid';
		end if;
		if player_total < 4 and p_team_numbers[player_index] <> player_index then
			raise exception 'players in games with fewer than four players need separate teams';
		end if;
	end loop;
	if player_total = 4 and (
		(select count(*) from unnest(p_team_numbers) as numbers(team_number) where team_number = 1) <> 2
		or (select count(*) from unnest(p_team_numbers) as numbers(team_number) where team_number = 2) <> 2
	) then
		raise exception 'four-player games need two teams of two';
	end if;

	insert into public.games (owner_id, player_count, starting_points)
	values (auth.uid(), player_total, p_starting_points)
	returning id into new_game_id;

	for team_index in 1..team_total loop
		insert into public.game_teams (game_id, team_order, name)
		values (new_game_id, team_index, 'Team ' || team_index);
	end loop;

	for player_index in 1..player_total loop
		clean_name := btrim(p_player_names[player_index]);
		if char_length(clean_name) not between 1 and 80 then
			raise exception 'player names must contain between 1 and 80 characters';
		end if;

		select id into new_team_id
		from public.game_teams
		where game_id = new_game_id and team_order = p_team_numbers[player_index];

		insert into public.game_players (game_id, team_id, player_order, name)
		values (new_game_id, new_team_id, player_index, clean_name);
	end loop;

	return new_game_id;
end;
$$;

revoke all on function public.create_game(text[], integer, integer[]) from public;
grant execute on function public.create_game(text[], integer, integer[]) to authenticated;

drop function if exists public.apply_score_event(uuid, text, integer, uuid, text, boolean);

create or replace function public.apply_score_event(
	p_round_id uuid,
	p_title text,
	p_points integer,
	p_selected_team_id uuid,
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
	winning_team_id uuid;
	loser_team_ids uuid[];
	target_team_ids uuid[];
	target_player_ids uuid[];
	highest_remaining integer;
	next_round_id uuid;
	next_round_number integer;
	starting_points_for_game integer;
	effective_points integer;
	event_title text;
begin
	if auth.uid() is null then raise exception 'not authenticated'; end if;
	if p_points is null or p_points >= 0 then raise exception 'score events must subtract points'; end if;
	if char_length(btrim(coalesce(p_title, ''))) not between 1 and 80 then raise exception 'event title is invalid'; end if;
	if p_mode not in ('wins', 'loses') then raise exception 'score mode is invalid'; end if;

	select rounds.game_id, games.starting_points
	into game_id_for_round, starting_points_for_game
	from public.rounds
	join public.games on games.id = rounds.game_id
	where rounds.id = p_round_id and rounds.status = 'active' and games.owner_id = auth.uid();
	if not found then raise exception 'active round not found'; end if;

	if not exists (select 1 from public.game_teams where id = p_selected_team_id and game_id = game_id_for_round) then
		raise exception 'selected team does not belong to this game';
	end if;

	effective_points := p_points * case when p_spritz then 2 else 1 end;
	event_title := btrim(p_title) || case when p_spritz then ' (Gspritzt)' else '' end;

	if p_mode = 'wins' then
		target_team_ids := array[p_selected_team_id];
	else
		select array_agg(id order by team_order) into target_team_ids
		from public.game_teams
		where game_id = game_id_for_round and id <> p_selected_team_id;
	end if;

	select array_agg(id order by player_order) into target_player_ids
	from public.game_players
	where game_id = game_id_for_round and team_id = any(target_team_ids);

	insert into public.round_events (round_id, title, points, mode, selected_team_id, spritz)
	values (p_round_id, event_title, effective_points, p_mode, p_selected_team_id, p_spritz)
	returning id into event_id;

	insert into public.round_event_players (event_id, player_id)
	select event_id, player_id from unnest(target_player_ids) as target(player_id);

	update public.round_player_scores
	set remaining_points = remaining_points + effective_points
	where round_id = p_round_id and player_id = any(target_player_ids);

	select team_id into winning_team_id
	from (
		select game_players.team_id, min(round_player_scores.remaining_points) as team_score, min(game_players.player_order) as team_order
		from public.round_player_scores
		join public.game_players on game_players.id = round_player_scores.player_id
		where round_player_scores.round_id = p_round_id
		group by game_players.team_id
	) as team_scores
	where team_score <= 0
	order by team_order
	limit 1;

	if winning_team_id is not null then
		select max(team_score) into highest_remaining
		from (
			select game_players.team_id, min(round_player_scores.remaining_points) as team_score
			from public.round_player_scores
			join public.game_players on game_players.id = round_player_scores.player_id
			where round_player_scores.round_id = p_round_id and game_players.team_id <> winning_team_id
			group by game_players.team_id
		) as team_scores;

		select array_agg(team_id) into loser_team_ids
		from (
			select game_players.team_id, min(round_player_scores.remaining_points) as team_score
			from public.round_player_scores
			join public.game_players on game_players.id = round_player_scores.player_id
			where round_player_scores.round_id = p_round_id and game_players.team_id <> winning_team_id
			group by game_players.team_id
		) as team_scores
		where team_score = highest_remaining;

		insert into public.round_bummerl_awards (round_id, event_id, team_id, player_id)
		select p_round_id, event_id, loser.team_id, representative.id
		from unnest(loser_team_ids) as loser(team_id)
		join lateral (
			select id from public.game_players
			where game_players.team_id = loser.team_id
			order by player_order limit 1
		) as representative on true;

		update public.game_teams set bummerl_count = bummerl_count + 1 where id = any(loser_team_ids);

		update public.rounds
		set status = 'completed', winner_team_id = winning_team_id,
			winner_player_id = (select id from public.game_players where team_id = winning_team_id order by player_order limit 1),
			completed_at = timezone('utc', now())
		where id = p_round_id;

		select coalesce(max(round_number), 0) + 1 into next_round_number
		from public.rounds where game_id = game_id_for_round;
		insert into public.rounds (game_id, round_number, starting_points)
		values (game_id_for_round, next_round_number, starting_points_for_game)
		returning id into next_round_id;
		insert into public.round_player_scores (round_id, player_id, remaining_points)
		select next_round_id, id, starting_points_for_game
		from public.game_players where game_id = game_id_for_round;
	end if;

	update public.games set last_event_at = timezone('utc', now()) where id = game_id_for_round;
	return jsonb_build_object('round_completed', winning_team_id is not null, 'winner_team_id', winning_team_id, 'loser_team_ids', coalesce(loser_team_ids, array[]::uuid[]), 'next_round_id', next_round_id);
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
	award_team_id uuid;
begin
	if auth.uid() is null then raise exception 'not authenticated'; end if;
	if not exists (select 1 from public.games where id = p_game_id and owner_id = auth.uid()) then raise exception 'game not found'; end if;

	select round_events.id, round_events.round_id, round_events.points, rounds.status
	into last_event_id, last_round_id, last_event_points, last_round_status
	from public.round_events
	join public.rounds on rounds.id = round_events.round_id
	where rounds.game_id = p_game_id
	order by round_events.created_at desc, round_events.id desc limit 1;
	if not found then raise exception 'no score event to undo'; end if;

	if last_round_status = 'completed' then
		select id into active_round_id
		from public.rounds
		where game_id = p_game_id and status = 'active'
		and round_number = (select round_number + 1 from public.rounds where id = last_round_id)
		and not exists (select 1 from public.round_events where round_id = rounds.id);
		if active_round_id is null then raise exception 'the completed round cannot be undone after the next round has started'; end if;

		delete from public.rounds where id = active_round_id;
		update public.rounds set status = 'active', winner_team_id = null, winner_player_id = null, completed_at = null where id = last_round_id;
		for award_team_id in select team_id from public.round_bummerl_awards where event_id = last_event_id loop
			update public.game_teams set bummerl_count = greatest(0, bummerl_count - 1) where id = award_team_id;
		end loop;
		delete from public.round_bummerl_awards where event_id = last_event_id;
	end if;

	update public.round_player_scores
	set remaining_points = remaining_points - last_event_points
	where round_id = last_round_id
	and player_id in (select player_id from public.round_event_players where event_id = last_event_id);
	delete from public.round_events where id = last_event_id;

	select max(round_events.created_at) into previous_event_at
	from public.round_events join public.rounds on rounds.id = round_events.round_id
	where rounds.game_id = p_game_id;
	update public.games set last_event_at = coalesce(previous_event_at, started_at) where id = p_game_id;
	return jsonb_build_object('undone_event_id', last_event_id, 'round_reopened', last_round_status = 'completed');
end;
$$;

revoke all on function public.undo_last_score_event(uuid) from public;
grant execute on function public.undo_last_score_event(uuid) to authenticated;
