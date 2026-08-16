<script lang="ts">
	import { goto, invalidateAll } from '$app/navigation';
	import { resolve } from '$app/paths';
	import GameList from '$lib/components/game/game-list.svelte';
	import { normalizeOnlineGame } from '$lib/game/online-repository';

	let { data } = $props();
	const games = $derived(data.games.map((game) => normalizeOnlineGame(game, [])));
	async function archive(gameId: string) {
		const response = await fetch('/app?/archive', {
			method: 'POST',
			body: new URLSearchParams({ gameId })
		});
		if (!response.ok) throw new Error('Dieses Spiel konnte nicht archiviert werden.');
		await invalidateAll();
	}
</script>

<svelte:head><title>Meine Spiele | bummerl</title></svelte:head>
<GameList
	{games}
	mode="online"
	userName={data.user.user_metadata?.first_name ?? 'Spieler'}
	onOpen={(gameId) => goto(resolve(`/app/games/${gameId}`))}
	onCreate={() => goto(resolve('/app/games/new'))}
	onArchive={archive}
/>
