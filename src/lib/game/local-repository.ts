import {
	applyLocalEvent,
	createLocalGame,
	undoLocalEvent,
	type LocalGame,
	type LocalGames
} from './local-game';
import type { Game, GameRepository } from './model';

function toGame(local: LocalGame): Game {
	return {
		id: local.id,
		playerCount: local.playerCount,
		startingPoints: local.startingPoints,
		startedAt: local.createdAt,
		lastEventAt: local.updatedAt,
		teams: local.teams.map((team) => ({
			id: team.id,
			name: team.name,
			order: team.playerOrder,
			bummerlCount: team.bummerlCount
		})),
		rounds: local.rounds.map((round) => ({
			id: round.id,
			number: round.number,
			status: round.status,
			winnerTeamId: round.winnerTeamId,
			scores: round.scores,
			events: round.events
		}))
	};
}

/** Keeps browser storage behind the same contract as the remote game service. */
export function createLocalRepository(
	getGames: () => LocalGames,
	setGames: (games: LocalGames) => void
): GameRepository {
	return {
		mode: 'offline',
		async createGame({ playerNames, startingPoints }) {
			const game = createLocalGame(playerNames, startingPoints);
			setGames({ ...getGames(), [game.id]: game });
			return toGame(game);
		},
		async archiveGame(gameId) {
			const games = { ...getGames() };
			delete games[gameId];
			setGames(games);
		},
		async startRound() {},
		async applyEvent(input) {
			const game = getGames()[input.gameId];
			if (!game) throw new Error('Dieses Spiel wurde nicht gefunden.');
			setGames({
				...getGames(),
				[game.id]: applyLocalEvent(
					game,
					input.selectedTeamId,
					input.title,
					input.points,
					input.mode,
					input.spritz
				)
			});
		},
		async undoLastEvent(gameId) {
			const game = getGames()[gameId];
			const previous = game && undoLocalEvent(game);
			if (previous) setGames({ ...getGames(), [gameId]: previous });
		}
	};
}

export function localGamesToGames(games: LocalGames) {
	return Object.values(games).map(toGame);
}
