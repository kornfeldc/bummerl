create extension if not exists "pgcrypto";

create table public.games (
	id uuid primary key default gen_random_uuid(),
	owner_id uuid not null references auth.users (id) on delete cascade,
	player_count smallint not null check (player_count between 2 and 4),
	starting_points integer not null check (starting_points > 0),
	started_at timestamptz not null default timezone('utc', now()),
	last_event_at timestamptz not null default timezone('utc', now()),
	archived_at timestamptz
);

create index games_owner_active_idx on public.games (owner_id, archived_at, last_event_at desc);

create table public.game_players (
	id uuid primary key default gen_random_uuid(),
	game_id uuid not null references public.games (id) on delete cascade,
	player_order smallint not null check (player_order between 1 and 4),
	name text not null check (char_length(btrim(name)) between 1 and 80),
	bummerl_count integer not null default 0 check (bummerl_count >= 0),
	unique (game_id, player_order)
);

create index game_players_game_idx on public.game_players (game_id, player_order);

alter table public.games enable row level security;
alter table public.game_players enable row level security;

create policy "Users can view their own games"
on public.games for select
using (owner_id = (select auth.uid()));

create policy "Users can create their own games"
on public.games for insert
with check (owner_id = (select auth.uid()));

create policy "Users can update their own games"
on public.games for update
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "Users can view players in their own games"
on public.game_players for select
using (
	exists (
		select 1 from public.games
		where games.id = game_players.game_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can create players in their own games"
on public.game_players for insert
with check (
	exists (
		select 1 from public.games
		where games.id = game_players.game_id
		and games.owner_id = (select auth.uid())
	)
);

create policy "Users can update players in their own games"
on public.game_players for update
using (
	exists (
		select 1 from public.games
		where games.id = game_players.game_id
		and games.owner_id = (select auth.uid())
	)
)
with check (
	exists (
		select 1 from public.games
		where games.id = game_players.game_id
		and games.owner_id = (select auth.uid())
	)
);

create or replace function public.create_game(
	p_player_names text[],
	p_starting_points integer
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
	new_game_id uuid;
	player_index integer;
	clean_name text;
	player_total integer;
begin
	if auth.uid() is null then
		raise exception 'not authenticated';
	end if;

	player_total := coalesce(cardinality(p_player_names), 0);
	if player_total not between 2 and 4 then
		raise exception 'a game needs between 2 and 4 players';
	end if;

	if p_starting_points is null or p_starting_points <= 0 then
		raise exception 'starting points must be greater than zero';
	end if;

	insert into public.games (owner_id, player_count, starting_points)
	values (auth.uid(), player_total, p_starting_points)
	returning id into new_game_id;

	for player_index in 1..player_total loop
		clean_name := btrim(p_player_names[player_index]);
		if char_length(clean_name) not between 1 and 80 then
			raise exception 'player names must contain between 1 and 80 characters';
		end if;

		insert into public.game_players (game_id, player_order, name)
		values (new_game_id, player_index, clean_name);
	end loop;

	return new_game_id;
end;
$$;

revoke all on function public.create_game(text[], integer) from public;
grant execute on function public.create_game(text[], integer) to authenticated;
