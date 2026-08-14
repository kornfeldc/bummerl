type DashboardPlayer = {
	id: string;
	name: string;
	bummerl_count: number;
};

type DashboardGame = {
	id: string;
	player_count: number;
	starting_points: number;
	started_at: string;
	last_event_at: string;
	game_players: DashboardPlayer[];
};

export const load = async ({ locals }) => {
	if (!locals.supabase) return { games: [] as DashboardGame[] };

	const { data, error } = await locals.supabase
		.from('games')
		.select(
			'id, player_count, starting_points, started_at, last_event_at, game_players(id, name, bummerl_count)'
		)
		.is('archived_at', null)
		.order('last_event_at', { ascending: false });

	if (error) return { games: [] as DashboardGame[] };
	return { games: (data ?? []) as unknown as DashboardGame[] };
};
