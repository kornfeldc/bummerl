<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import GameDetail from '$lib/components/game/game-detail.svelte';
	import { createOnlineRepository, normalizeOnlineGame } from '$lib/game/online-repository';

	let { data } = $props();
	const repository = createOnlineRepository('/app');
	const game = $derived(normalizeOnlineGame(data.game, data.rounds));
</script>

<svelte:head><title>{game.teams.map((team) => team.name).join(' · ')} | bummerl</title></svelte:head
>
<GameDetail {game} {repository} onBack={() => goto(resolve('/app'))} />
