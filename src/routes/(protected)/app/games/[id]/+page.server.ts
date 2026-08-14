import { error, fail, redirect } from '@sveltejs/kit';

type GamePlayer = {
	id: string;
	name: string;
	player_order: number;
	team_id: string;
};

type GameTeam = {
	id: string;
	name: string;
	team_order: number;
	bummerl_count: number;
	game_players: GamePlayer[];
};

type Game = {
	id: string;
	player_count: number;
	starting_points: number;
	started_at: string;
	last_event_at: string;
	game_teams: GameTeam[];
};

type Round = {
	id: string;
	round_number: number;
	starting_points: number;
	status: 'active' | 'completed';
	winner_team_id: string | null;
	started_at: string;
	completed_at: string | null;
	round_player_scores: Array<{ player_id: string; remaining_points: number }>;
	round_events: Array<{
		id: string;
		title: string;
		points: number;
		created_at: string;
		round_event_players: Array<{ player_id: string }>;
	}>;
};

export const load = async ({ locals, params }) => {
	if (!locals.supabase) error(503, 'Supabase ist nicht konfiguriert.');

	const { data: gameData, error: gameError } = await locals.supabase
		.from('games')
		.select(
			'id, player_count, starting_points, started_at, last_event_at, game_teams(id, name, team_order, bummerl_count, game_players(id, name, player_order, team_id))'
		)
		.eq('id', params.id)
		.maybeSingle();

	if (gameError) error(500, 'Das Spiel konnte nicht geladen werden.');
	if (!gameData) error(404, 'Dieses Spiel wurde nicht gefunden.');

	const { data: roundData, error: roundError } = await locals.supabase
		.from('rounds')
		.select(
			'id, round_number, starting_points, status, winner_team_id, started_at, completed_at, round_player_scores(player_id, remaining_points), round_events(id, title, points, created_at, round_event_players(player_id))'
		)
		.eq('game_id', params.id)
		.order('round_number', { ascending: true });

	if (roundError) error(500, 'Die Runden konnten nicht geladen werden.');

	return {
		game: gameData as unknown as Game,
		rounds: (roundData ?? []) as unknown as Round[]
	};
};

export const actions = {
	startRound: async ({ locals, params }) => {
		const { user } = await locals.safeGetSession();
		if (!user || !locals.supabase) return fail(401, { message: 'Bitte melde dich zuerst an.' });

		const { error: startError } = await locals.supabase.rpc('start_round', {
			p_game_id: params.id
		});

		if (startError) return fail(400, { message: 'Die Runde konnte nicht gestartet werden.' });
		redirect(303, `/app/games/${params.id}`);
	},

	applyEvent: async ({ locals, params, request }) => {
		const { user } = await locals.safeGetSession();
		if (!user || !locals.supabase) return fail(401, { message: 'Bitte melde dich zuerst an.' });

		const formData = await request.formData();
		const action = formData.get('action');
		const selectedTeamId = formData.get('selectedTeamId');
		const mode = formData.get('mode');
		const spritz = formData.get('spritz') === 'on';
		const { data: game, error: gameError } = await locals.supabase
			.from('games')
			.select('player_count')
			.eq('id', params.id)
			.maybeSingle();

		if (gameError || !game) return fail(400, { message: 'Das Spiel konnte nicht geladen werden.' });
		if (spritz && game.player_count === 2) {
			return fail(400, { message: 'Gspritzt ist erst ab drei Spielern verfügbar.' });
		}

		if (
			typeof action !== 'string' ||
			typeof selectedTeamId !== 'string' ||
			!selectedTeamId ||
			typeof mode !== 'string'
		) {
			return fail(400, { message: 'Wähle ein Team, eine Punktaktion und das Ergebnis aus.' });
		}
		const separatorIndex = action.lastIndexOf('|');
		const title = action.slice(0, separatorIndex);
		const points = Number(action.slice(separatorIndex + 1));
		if (!title || !Number.isInteger(points) || points >= 0) {
			return fail(400, { message: 'Diese Punktaktion ist ungültig.' });
		}

		const { data: result, error: eventError } = await locals.supabase.rpc('apply_score_event', {
			p_round_id: formData.get('roundId'),
			p_title: title,
			p_points: points,
			p_selected_team_id: selectedTeamId,
			p_mode: mode,
			p_spritz: spritz
		});

		if (eventError || !result) {
			return fail(400, { message: 'Die Punktaktion konnte nicht gespeichert werden.' });
		}

		const outcome = result as { round_completed?: boolean };
		return {
			message: outcome.round_completed
				? 'Runde beendet. Die nächste Runde wurde eröffnet.'
				: 'Punkte gespeichert.'
		};
	},

	undoLastEvent: async ({ locals, params }) => {
		const { user } = await locals.safeGetSession();
		if (!user || !locals.supabase) return fail(401, { message: 'Bitte melde dich zuerst an.' });

		const { data: result, error: undoError } = await locals.supabase.rpc('undo_last_score_event', {
			p_game_id: params.id
		});

		if (undoError || !result) {
			return fail(400, {
				message: undoError?.message ?? 'Die letzte Aktion konnte nicht zurückgenommen werden.'
			});
		}

		return { message: 'Die letzte Punktaktion wurde zurückgenommen.' };
	}
};
