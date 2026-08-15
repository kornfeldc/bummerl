import { redirect } from '@sveltejs/kit';

export const load = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (user) redirect(303, '/app');
};
