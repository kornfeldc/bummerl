export type ScoreSnapshot = {
	id: string;
	playerOrder: number;
	remainingPoints: number;
};

export type RoundOutcome = {
	winnerId: string;
	loserIds: string[];
};

export function resolveRoundOutcome(scores: ScoreSnapshot[]): RoundOutcome | null {
	const winner = [...scores]
		.filter((score) => score.remainingPoints <= 0)
		.sort((left, right) => left.playerOrder - right.playerOrder)[0];

	if (!winner) return null;

	const remainingPlayers = scores.filter((score) => score.id !== winner.id);
	const highestRemaining = Math.max(...remainingPlayers.map((score) => score.remainingPoints));
	const loserIds = remainingPlayers
		.filter((score) => score.remainingPoints === highestRemaining)
		.map((score) => score.id);

	return { winnerId: winner.id, loserIds };
}
