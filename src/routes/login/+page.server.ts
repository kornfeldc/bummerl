import { fail, redirect } from '@sveltejs/kit';

export const actions = {
	default: async ({ locals, url }) => {
		if (!locals.supabase) {
			return fail(503, { message: 'Die Anmeldung ist noch nicht konfiguriert.' });
		}

		const redirectTo = `${url.origin}/auth/callback`;
		const { data, error } = await locals.supabase.auth.signInWithOAuth({
			provider: 'google',
			options: { redirectTo }
		});

		if (error || !data.url) {
			return fail(400, {
				message: error?.message ?? 'Die Anmeldung konnte nicht gestartet werden.'
			});
		}

		redirect(303, data.url);
	}
};
