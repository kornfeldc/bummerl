import { fail } from '@sveltejs/kit';

type DashboardTeam = {
	id: string;
	team_order: number;
	game_players: Array<{ id: string; name: string }>;
};

type DashboardGame = {
	id: string;
	player_count: number;
	starting_points: number;
	started_at: string;
	last_event_at: string;
	game_teams: DashboardTeam[];
};

export const load = async ({ locals }) => {
	if (!locals.supabase) return { games: [] as DashboardGame[] };

	const { data, error } = await locals.supabase
		.from('games')
		.select(
			'id, player_count, starting_points, started_at, last_event_at, game_teams(id, team_order, game_players(id, name))'
		)
		.is('archived_at', null)
		.order('last_event_at', { ascending: false });

	if (error) return { games: [] as DashboardGame[] };
	return { games: (data ?? []) as unknown as DashboardGame[] };
};

export const actions = {
	archive: async ({ locals, request }) => {
		const { user } = await locals.safeGetSession();
		if (!user || !locals.supabase) return fail(401, { message: 'Bitte melde dich zuerst an.' });

		const formData = await request.formData();
		const gameId = formData.get('gameId');
		if (typeof gameId !== 'string' || !gameId) {
			return fail(400, { message: 'Dieses Spiel konnte nicht archiviert werden.' });
		}

		const { error } = await locals.supabase
			.from('games')
			.update({ archived_at: new Date().toISOString() })
			.eq('id', gameId)
			.eq('owner_id', user.id);

		if (error) return fail(400, { message: 'Dieses Spiel konnte nicht archiviert werden.' });
		return { message: 'Spiel archiviert.' };
	}
};
