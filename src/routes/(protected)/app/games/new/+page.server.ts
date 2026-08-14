import { fail, redirect } from '@sveltejs/kit';

export const actions = {
	default: async ({ locals, request }) => {
		const { user } = await locals.safeGetSession();
		if (!user || !locals.supabase) {
			return fail(401, { message: 'Bitte melde dich zuerst an.' });
		}

		const formData = await request.formData();
		const playerCount = Number(formData.get('playerCount'));
		const startingPoints = Number(formData.get('startingPoints'));
		const playerNames = formData
			.getAll('playerName')
			.map((name) => (typeof name === 'string' ? name.trim() : ''));

		if (!Number.isInteger(playerCount) || playerCount < 2 || playerCount > 4) {
			return fail(400, { message: 'Wähle bitte zwei bis vier Spieler aus.' });
		}
		if (playerNames.length !== playerCount || playerNames.some((name) => name.length === 0)) {
			return fail(400, { message: 'Bitte gib für jeden Spieler einen Namen ein.', playerNames });
		}

		const teamNumbers = playerCount === 4 ? [1, 1, 2, 2] : playerNames.map((_, index) => index + 1);
		if (!Number.isInteger(startingPoints) || startingPoints < 1 || startingPoints > 999) {
			return fail(400, {
				message: 'Die Startpunkte müssen zwischen 1 und 999 liegen.',
				playerNames
			});
		}

		const { data: gameId, error } = await locals.supabase.rpc('create_game_and_start_round', {
			p_player_names: playerNames,
			p_starting_points: startingPoints,
			p_team_numbers: teamNumbers
		});

		if (error || !gameId) {
			return fail(400, {
				message: 'Das Spiel konnte nicht gespeichert werden. Bitte versuche es noch einmal.',
				playerNames
			});
		}

		redirect(303, `/app/games/${gameId}`);
	}
};
