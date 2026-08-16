import { invalidateAll } from '$app/navigation';
import type { Game, GameRepository } from './model';

async function post(url: string, values: Record<string, string>) {
	const body = new URLSearchParams(values);
	const response = await fetch(url, { method: 'POST', body });
	if (!response.ok) throw new Error('Die Änderung konnte nicht gespeichert werden.');
	await invalidateAll();
	return response;
}

/** Remote implementation of the same contract used by the local-storage mode. */
export function createOnlineRepository(basePath: string): GameRepository {
	return {
		mode: 'online',
		async createGame({ playerNames, startingPoints }) {
			const body = new URLSearchParams({
				playerCount: String(playerNames.length),
				startingPoints: String(startingPoints)
			});
			for (const name of playerNames) body.append('playerName', name);
			const response = await fetch(`${basePath}/games/new`, {
				method: 'POST',
				body,
				redirect: 'follow'
			});
			if (!response.ok) throw new Error('Das Spiel konnte nicht gespeichert werden.');
			const gameId = new URL(response.url).pathname.match(/\/games\/([^/]+)$/)?.[1];
			if (!gameId) throw new Error('Das Spiel konnte nicht geöffnet werden.');
			const teams = (
				playerNames.length === 4
					? [playerNames.slice(0, 2), playerNames.slice(2)]
					: playerNames.map((name) => [name])
			).map((names, index) => ({
				id: `pending-${index}`,
				name: names.join(' + '),
				order: index + 1,
				bummerlCount: 0
			}));
			return {
				id: gameId,
				playerCount: playerNames.length,
				startingPoints,
				startedAt: new Date().toISOString(),
				lastEventAt: new Date().toISOString(),
				teams,
				rounds: []
			};
		},
		async archiveGame(gameId) {
			await post(`${basePath}?/archive`, { gameId });
		},
		async startRound(gameId) {
			await post(`${basePath}/games/${gameId}?/startRound`, {});
		},
		async applyEvent(input) {
			await post(`${basePath}/games/${input.gameId}?/applyEvent`, {
				roundId: input.roundId,
				selectedTeamId: input.selectedTeamId,
				action: `${input.title}|${input.points}`,
				mode: input.mode,
				spritz: input.spritz ? 'on' : ''
			});
		},
		async undoLastEvent(gameId) {
			await post(`${basePath}/games/${gameId}?/undoLastEvent`, {});
		}
	};
}

type OnlineTeam = {
	id: string;
	team_order: number;
	bummerl_count?: number;
	game_players: Array<{ id?: string; name: string }>;
};

export function normalizeOnlineGame(
	game: {
		id: string;
		player_count: number;
		starting_points: number;
		started_at: string;
		last_event_at: string;
		game_teams: OnlineTeam[];
	},
	rounds: Array<{
		id: string;
		round_number: number;
		status: 'active' | 'completed';
		winner_team_id: string | null;
		round_player_scores: Array<{ player_id: string; remaining_points: number }>;
		round_events: Array<{
			id: string;
			title: string;
			points: number;
			mode: 'wins' | 'loses' | null;
			selected_team_id: string | null;
			round_event_players: Array<{ player_id: string }>;
		}>;
	}>
): Game {
	const teams = game.game_teams.map((team) => ({
		id: team.id,
		name: team.game_players.map((player) => player.name).join(' + '),
		order: team.team_order,
		bummerlCount: team.bummerl_count ?? 0
	}));
	const playerTeamIds = new Map<string, string>();
	for (const team of game.game_teams)
		for (const player of team.game_players) if (player.id) playerTeamIds.set(player.id, team.id);
	return {
		id: game.id,
		playerCount: game.player_count,
		startingPoints: game.starting_points,
		startedAt: game.started_at,
		lastEventAt: game.last_event_at,
		teams,
		rounds: rounds.map((round) => ({
			id: round.id,
			number: round.round_number,
			status: round.status,
			winnerTeamId: round.winner_team_id,
			scores: Object.fromEntries(
				teams.map((team) => [
					team.id,
					round.round_player_scores.find((score) => playerTeamIds.get(score.player_id) === team.id)
						?.remaining_points ?? game.starting_points
				])
			),
			events: round.round_events.map((event) => ({
				id: event.id,
				title: event.title,
				points: event.points,
				mode: event.mode ?? undefined,
				selectedTeamId: event.selected_team_id ?? undefined,
				targetTeamIds: [
					...new Set(
						event.round_event_players
							.map((player) => playerTeamIds.get(player.player_id))
							.filter((teamId): teamId is string => Boolean(teamId))
					)
				]
			}))
		}))
	};
}
