import { redirect, type RequestEvent } from '@sveltejs/kit';

function publicOrigin({ request, url }: RequestEvent) {
	const originatingPage = request.headers.get('origin') ?? request.headers.get('referer');
	if (originatingPage) {
		try {
			return new URL(originatingPage).origin;
		} catch {
			// Fall back to the proxy headers when the browser did not send a valid origin.
		}
	}

	const forwardedHost = request.headers.get('x-forwarded-host')?.split(',')[0]?.trim();
	const host = forwardedHost ?? request.headers.get('host');
	const forwardedProtocol = request.headers.get('x-forwarded-proto')?.split(',')[0]?.trim();

	if (!host) return url.origin;

	return `${forwardedProtocol ?? url.protocol.replace(':', '')}://${host}`;
}

export const GET = async (event) => {
	const { locals, url } = event;
	const next = url.searchParams.get('next');
	const destination = next?.startsWith('/') && !next.startsWith('//') ? next : '/app';

	if (!locals.supabase) redirect(303, '/');

	const callbackUrl = new URL('/auth/callback', publicOrigin(event));
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
};
