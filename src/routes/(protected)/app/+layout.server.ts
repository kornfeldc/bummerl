import { redirect } from '@sveltejs/kit';

export const load = async ({ locals, url }) => {
	const { user } = await locals.safeGetSession();
	if (!user) redirect(303, `/auth/google?next=${encodeURIComponent(url.pathname)}`);

	return { user };
};
