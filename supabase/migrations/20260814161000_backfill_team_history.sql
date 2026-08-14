update public.rounds
set winner_team_id = game_players.team_id
from public.game_players
where rounds.winner_player_id = game_players.id
and rounds.winner_team_id is null;

update public.round_bummerl_awards
set team_id = game_players.team_id
from public.game_players
where round_bummerl_awards.player_id = game_players.id
and round_bummerl_awards.team_id is null;

update public.game_teams
set bummerl_count = coalesce(legacy_counts.bummerl_count, 0)
from (
	select team_id, max(bummerl_count) as bummerl_count
	from public.game_players
	group by team_id
) as legacy_counts
where game_teams.id = legacy_counts.team_id;
