<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { SvelteURLSearchParams } from 'svelte/reactivity';
	import GameSetup from '$lib/components/game/game-setup.svelte';

	async function create({
		playerNames,
		startingPoints
	}: {
		playerNames: string[];
		startingPoints: number;
	}) {
		const body = new SvelteURLSearchParams({
			playerCount: String(playerNames.length),
			startingPoints: String(startingPoints)
		});
		for (const name of playerNames) body.append('playerName', name);
		const response = await fetch('/app/games/new', { method: 'POST', body, redirect: 'follow' });
		if (!response.ok) throw new Error('Das Spiel konnte nicht gespeichert werden.');
		const match = new URL(response.url).pathname.match(/\/app\/games\/([^/]+)$/);
		if (!match) throw new Error('Das Spiel konnte nicht geöffnet werden.');
		await goto(resolve(`/app/games/${match[1]}`));
	}
</script>

<svelte:head><title>Neues Spiel | bummerl</title></svelte:head>
<GameSetup onCreate={create} onCancel={() => goto(resolve('/app'))} />
