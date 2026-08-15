const CACHE_NAME = 'bummerl-offline-v2';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (event) => {
	const url = new URL(event.request.url);
	const isOfflinePage = event.request.mode === 'navigate' && url.pathname === '/offline';
	const isStaticAsset =
		url.pathname.startsWith('/_app/') ||
		url.pathname.startsWith('/icons/') ||
		['script', 'style', 'image', 'font'].includes(event.request.destination);

	if (
		event.request.method !== 'GET' ||
		url.origin !== self.location.origin ||
		(!isOfflinePage && !isStaticAsset)
	)
		return;

	event.respondWith(
		(async () => {
			try {
				const response = await fetch(event.request);
				if (response.ok) {
					const cache = await caches.open(CACHE_NAME);
					cache.put(event.request, response.clone());
				}
				return response;
			} catch {
				const cached = await caches.match(event.request);
				if (cached) return cached;
				throw new Error('Die angeforderte Seite ist noch nicht offline verfügbar.');
			}
		})()
	);
});
