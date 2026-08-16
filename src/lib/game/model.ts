export type GameMode = 'online' | 'offline';

export type GameTeam = {
	id: string;
	name: string;
	order: number;
	bummerlCount: number;
};

export type GameEvent = {
	id: string;
	title: string;
	points: number;
	targetTeamIds: string[];
	selectedTeamId?: string;
	mode?: 'wins' | 'loses';
};

export type GameRound = {
	id: string;
	number: number;
	status: 'active' | 'completed';
	winnerTeamId: string | null;
	scores: Record<string, number>;
	events: GameEvent[];
};

export type Game = {
	id: string;
	playerCount: number;
	startingPoints: number;
	startedAt: string;
	lastEventAt: string;
	teams: GameTeam[];
	rounds: GameRound[];
};

export type GameRepository = {
	mode: GameMode;
	createGame(input: { playerNames: string[]; startingPoints: number }): Promise<Game>;
	archiveGame(gameId: string): Promise<void>;
	startRound(gameId: string): Promise<void>;
	applyEvent(input: {
		gameId: string;
		roundId: string;
		selectedTeamId: string;
		title: string;
		points: number;
		mode: 'wins' | 'loses';
		spritz: boolean;
	}): Promise<void>;
	undoLastEvent(gameId: string): Promise<void>;
};

export function gameTitle(game: Pick<Game, 'teams'>) {
	return game.teams
		.slice()
		.sort((left, right) => left.order - right.order)
		.map((team) => team.name)
		.join(' · ');
}
