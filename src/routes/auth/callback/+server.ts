import { redirect } from '@sveltejs/kit';

export const GET = async ({ url, locals }) => {
	const code = url.searchParams.get('code');
	const next = url.searchParams.get('next');
	const destination = next?.startsWith('/') && !next.startsWith('//') ? next : '/app';

	if (!code || !locals.supabase) redirect(303, '/');

	const { error } = await locals.supabase.auth.exchangeCodeForSession(code);
	if (error) redirect(303, '/');

	redirect(303, destination);
};
