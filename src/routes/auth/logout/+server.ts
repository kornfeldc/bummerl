import { redirect } from '@sveltejs/kit';

export const POST = async ({ locals }) => {
	if (locals.supabase) await locals.supabase.auth.signOut();
	redirect(303, '/');
};
