create or replace function public.create_game_and_start_round(
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
begin
	new_game_id := public.create_game(p_player_names, p_starting_points, p_team_numbers);
	perform public.start_round(new_game_id);
	return new_game_id;
end;
$$;

revoke all on function public.create_game_and_start_round(text[], integer, integer[]) from public;
grant execute on function public.create_game_and_start_round(text[], integer, integer[]) to authenticated;
