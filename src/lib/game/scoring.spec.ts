import { describe, expect, it } from 'vitest';
import { resolveRoundOutcome } from './scoring';

describe('resolveRoundOutcome', () => {
	it('does not complete while every player has points left', () => {
		expect(
			resolveRoundOutcome([
				{ id: 'anna', playerOrder: 1, remainingPoints: 2 },
				{ id: 'sepp', playerOrder: 2, remainingPoints: 7 }
			])
		).toBeNull();
	});

	it('gives the Bummerl to the player with the highest remaining score', () => {
		expect(
			resolveRoundOutcome([
				{ id: 'anna', playerOrder: 1, remainingPoints: 0 },
				{ id: 'sepp', playerOrder: 2, remainingPoints: 5 },
				{ id: 'michi', playerOrder: 3, remainingPoints: 3 }
			])
		).toEqual({ winnerId: 'anna', loserIds: ['sepp'] });
	});

	it('marks all tied highest scores as losers', () => {
		expect(
			resolveRoundOutcome([
				{ id: 'anna', playerOrder: 1, remainingPoints: -1 },
				{ id: 'sepp', playerOrder: 2, remainingPoints: 4 },
				{ id: 'michi', playerOrder: 3, remainingPoints: 4 }
			])
		).toEqual({ winnerId: 'anna', loserIds: ['sepp', 'michi'] });
	});

	it('uses player order if one action brings multiple players to zero', () => {
		expect(
			resolveRoundOutcome([
				{ id: 'sepp', playerOrder: 2, remainingPoints: 0 },
				{ id: 'anna', playerOrder: 1, remainingPoints: -2 },
				{ id: 'michi', playerOrder: 3, remainingPoints: 6 }
			])
		).toEqual({ winnerId: 'anna', loserIds: ['michi'] });
	});
});
