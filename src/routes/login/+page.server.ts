import { redirect } from '@sveltejs/kit';

export const actions = {
	default: async ({ locals, url }) => {
		if (!locals.supabase) redirect(303, '/');

		const next = url.searchParams.get('next');
		const destination = next?.startsWith('/') && !next.startsWith('//') ? next : '/app';
		const callbackUrl = new URL('/auth/callback', url.origin);
		callbackUrl.searchParams.set('next', destination);
		const { data, error } = await locals.supabase.auth.signInWithOAuth({
			provider: 'google',
			options: {
				redirectTo: callbackUrl.toString(),
				queryParams: { prompt: 'select_account' }
			}
		});

		if (error || !data.url) redirect(303, '/');

		redirect(303, data.url);
	}
};
