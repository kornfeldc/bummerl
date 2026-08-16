<script lang="ts">
	import { onMount } from 'svelte';
	import SiteHeader from '$lib/components/site-header.svelte';
	import GameDetail from '$lib/components/game/game-detail.svelte';
	import GameList from '$lib/components/game/game-list.svelte';
	import GameSetup from '$lib/components/game/game-setup.svelte';
	import { createLocalRepository, localGamesToGames } from '$lib/game/local-repository';
	import { loadLocalGames, saveLocalGames, type LocalGames } from '$lib/game/local-game';
	import { CARD_SHUFFLE_MIN_DURATION_MS } from '$lib/loading';

	let games = $state<LocalGames>({});
	let screen = $state<'list' | 'setup' | 'detail'>('list');
	let selectedGameId = $state<string | null>(null);
	let ready = $state(false);
	const repository = createLocalRepository(
		() => games,
		(next) => (games = next)
	);
	const gameList = $derived(
		localGamesToGames(games).sort((a, b) => b.lastEventAt.localeCompare(a.lastEventAt))
	);
	const selectedGame = $derived(
		selectedGameId ? localGamesToGames(games).find((game) => game.id === selectedGameId) : undefined
	);

	onMount(() => {
		games = loadLocalGames();
		const gameId = new URLSearchParams(window.location.search).get('game');
		if (gameId && games[gameId]) {
			selectedGameId = gameId;
			screen = 'detail';
		}
		ready = true;
	});
	$effect(() => {
		if (ready) saveLocalGames(games);
	});
	function open(gameId: string) {
		selectedGameId = gameId;
		screen = 'detail';
		window.history.replaceState({}, '', `/offline?game=${gameId}`);
	}
	function back() {
		selectedGameId = null;
		screen = 'list';
		window.history.replaceState({}, '', '/offline');
	}
	async function create(input: { playerNames: string[]; startingPoints: number }) {
		const createdAt = Date.now();
		const game = await repository.createGame(input);
		const remainingDuration = CARD_SHUFFLE_MIN_DURATION_MS - (Date.now() - createdAt);
		if (remainingDuration > 0) {
			await new Promise((resolve) => setTimeout(resolve, remainingDuration));
		}
		open(game.id);
	}
</script>

<svelte:head
	><title>Offline spielen | bummerl</title><meta
		name="description"
		content="Der digitale Zählblock für eure Schnapsen-Runden."
	/></svelte:head
>
<SiteHeader />
{#if screen === 'list'}
	<GameList
		games={gameList}
		mode="offline"
		onOpen={open}
		onCreate={() => (screen = 'setup')}
		onArchive={async (gameId) => {
			await repository.archiveGame(gameId);
		}}
	/>
{:else if screen === 'setup'}
	<GameSetup onCreate={create} onCancel={back} />
{:else if selectedGame}
	<GameDetail game={selectedGame} {repository} onBack={back} />
{/if}
