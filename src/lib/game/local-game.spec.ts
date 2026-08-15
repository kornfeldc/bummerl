import { describe, expect, it } from 'vitest';
import { applyLocalEvent, createLocalGame, undoLocalEvent } from './local-game';

describe('local game scoring', () => {
	it('keeps a game entirely as an in-memory local state object', () => {
		const game = createLocalGame(['Anna', 'Sepp'], 7);

		expect(game.rounds[0]).toMatchObject({ number: 1, status: 'active' });
		expect(Object.values(game.rounds[0].scores)).toEqual([7, 7]);
	});

	it('starts the next round and awards a Bummerl when a team reaches zero', () => {
		const game = createLocalGame(['Anna', 'Sepp'], 7);
		const anna = game.teams[0].id;
		const sepp = game.teams[1].id;
		const scored = applyLocalEvent(game, anna, '7er', -7, 'wins', false);

		expect(scored.rounds).toHaveLength(2);
		expect(scored.rounds[0]).toMatchObject({ status: 'completed', winnerTeamId: anna });
		expect(scored.teams.find((team) => team.id === sepp)?.bummerlCount).toBe(1);
		expect(scored.rounds[1].scores).toEqual({ [anna]: 7, [sepp]: 7 });
	});

	it('undoes a completed round including its Bummerl award', () => {
		const game = createLocalGame(['Anna', 'Sepp'], 7);
		const anna = game.teams[0].id;
		const scored = applyLocalEvent(game, anna, '7er', -7, 'wins', false);
		const undone = undoLocalEvent(scored);

		expect(undone).toMatchObject({ rounds: [{ status: 'active' }] });
		expect(undone?.rounds).toHaveLength(1);
		expect(undone?.teams.map((team) => team.bummerlCount)).toEqual([0, 0]);
	});

	it('accepts reactive proxy state from the local Svelte store', () => {
		const game = new Proxy(createLocalGame(['Anna', 'Sepp'], 7), {});
		const scored = applyLocalEvent(game, game.teams[0].id, '1er', -1, 'wins', false);

		expect(scored.rounds[0].scores[game.teams[0].id]).toBe(6);
	});
});
