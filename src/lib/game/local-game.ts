import { resolveRoundOutcome } from './scoring';

export type LocalTeam = {
	id: string;

	name: string;

	playerOrder: number;

	bummerlCount: number;
};

export type LocalEvent = {
	id: string;

	title: string;

	points: number;

	targetTeamIds: string[];

	selectedTeamId: string;

	mode: 'wins' | 'loses';
};

export type LocalRound = {
	id: string;

	number: number;

	status: 'active' | 'completed';

	winnerTeamId: string | null;

	scores: Record<string, number>;

	events: LocalEvent[];
};

export type LocalGame = {
	id: string;

	playerCount: number;

	startingPoints: number;

	createdAt: string;

	updatedAt: string;

	teams: LocalTeam[];

	rounds: LocalRound[];

	undoStates: Omit<LocalGame, 'undoStates'>[];
};

export type LocalGames = Record<string, LocalGame>;

const storageKey = 'bummerl:local-games:v1';

function clone<T>(value: T): T {
	return JSON.parse(JSON.stringify(value)) as T;
}

function id() {
	if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();

	const bytes = new Uint8Array(16);
	if (globalThis.crypto?.getRandomValues) {
		globalThis.crypto.getRandomValues(bytes);
	} else {
		for (let index = 0; index < bytes.length; index += 1) {
			bytes[index] = Math.floor(Math.random() * 256);
		}
	}
	bytes[6] = (bytes[6] & 0x0f) | 0x40;
	bytes[8] = (bytes[8] & 0x3f) | 0x80;
	const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
	return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function snapshot(game: LocalGame): Omit<LocalGame, 'undoStates'> {
	const state = clone(game);
	return {
		id: state.id,
		playerCount: state.playerCount,
		startingPoints: state.startingPoints,
		createdAt: state.createdAt,
		updatedAt: state.updatedAt,
		teams: state.teams,
		rounds: state.rounds
	};
}

function newRound(game: LocalGame, number: number): LocalRound {
	return {
		id: id(),

		number,

		status: 'active',

		winnerTeamId: null,

		scores: Object.fromEntries(game.teams.map((team) => [team.id, game.startingPoints])),

		events: []
	};
}

export function createLocalGame(playerNames: string[], startingPoints: number): LocalGame {
	const playerCount = playerNames.length;

	const teams = (
		playerCount === 4
			? [playerNames.slice(0, 2), playerNames.slice(2, 4)]
			: playerNames.map((name) => [name])
	).map((names, index) => ({
		id: id(),

		name: names.join(' + '),

		playerOrder: index + 1,

		bummerlCount: 0
	}));

	const game: LocalGame = {
		id: id(),

		playerCount,

		startingPoints,

		createdAt: new Date().toISOString(),

		updatedAt: new Date().toISOString(),

		teams,

		rounds: [],

		undoStates: []
	};

	game.rounds.push(newRound(game, 1));

	return game;
}

export function applyLocalEvent(
	game: LocalGame,

	selectedTeamId: string,

	title: string,

	points: number,

	mode: 'wins' | 'loses',

	spritz: boolean
): LocalGame {
	const next = clone(game);

	const round = next.rounds.find((candidate) => candidate.status === 'active');

	if (!round) throw new Error('Keine aktive Runde vorhanden.');

	const targetTeamIds = next.teams

		.filter((team) => (mode === 'wins' ? team.id === selectedTeamId : team.id !== selectedTeamId))

		.map((team) => team.id);

	if (targetTeamIds.length === 0) throw new Error('Ungültige Punkteingabe.');

	next.undoStates.push(snapshot(game));

	const appliedPoints = points * (spritz ? 2 : 1);

	for (const teamId of targetTeamIds) round.scores[teamId] += appliedPoints;

	round.events.push({
		id: id(),
		title: spritz ? `${title} · Gspritzt` : title,
		points: appliedPoints,
		targetTeamIds,

		selectedTeamId,

		mode
	});

	const outcome = resolveRoundOutcome(
		next.teams.map((team) => ({
			id: team.id,

			playerOrder: team.playerOrder,

			remainingPoints: round.scores[team.id]
		}))
	);

	if (outcome) {
		round.status = 'completed';

		round.winnerTeamId = outcome.winnerId;

		for (const teamId of outcome.loserIds) {
			const team = next.teams.find((candidate) => candidate.id === teamId);

			if (team) team.bummerlCount += 1;
		}

		next.rounds.push(newRound(next, round.number + 1));
	}

	next.updatedAt = new Date().toISOString();

	return next;
}

export function undoLocalEvent(game: LocalGame): LocalGame | null {
	const previous = game.undoStates.at(-1);

	if (!previous) return null;

	return { ...clone(previous), undoStates: game.undoStates.slice(0, -1) };
}

export function loadLocalGames(): LocalGames {
	if (typeof localStorage === 'undefined') return {};

	try {
		const games = JSON.parse(localStorage.getItem(storageKey) ?? '{}') as LocalGames;

		return Object.fromEntries(Object.entries(games).filter(([, game]) => game && game.id));
	} catch {
		return {};
	}
}

export function saveLocalGames(games: LocalGames) {
	localStorage.setItem(storageKey, JSON.stringify(games));
}
