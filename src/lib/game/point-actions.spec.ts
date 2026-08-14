import { describe, expect, it } from 'vitest';
import { pointActionGroups } from './point-actions';

describe('point action availability', () => {
	it('keeps only 1er, 2er, and 3er for two-player games', () => {
		const actions = pointActionGroups
			.flatMap((group) => group.actions)
			.filter((action) => action.availablePlayerCounts.includes(2));

		expect(actions.map((action) => action.title)).toEqual(['1er', '2er', '3er']);
	});

	it('makes all configured actions available for three-player games', () => {
		const allActions = pointActionGroups.flatMap((group) => group.actions);
		const availableActions = allActions.filter((action) =>
			action.availablePlayerCounts.includes(3)
		);

		expect(availableActions).toHaveLength(allActions.length);
	});

	it('keeps named actions unavailable for two-player games', () => {
		const namedActions = pointActionGroups
			.flatMap((group) => group.actions)
			.filter((action) => action.title === 'Bettler' || action.title === 'Schnapser');

		expect(namedActions.every((action) => !action.availablePlayerCounts.includes(2))).toBe(true);
	});
});
