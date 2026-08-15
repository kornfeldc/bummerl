<script lang="ts">
	import './layout.css';
	import { navigating } from '$app/state';
	import { onMount } from 'svelte';
	import CardShuffleLoading from '$lib/components/card-shuffle-loading.svelte';
	import { CARD_SHUFFLE_MIN_DURATION_MS } from '$lib/loading';
	import { ModeWatcher } from 'mode-watcher';

	let { children } = $props();
	let showGameNavigationLoader = $state(false);
	let gameNavigationStartedAt = 0;

	onMount(() => {
		if ('serviceWorker' in navigator) navigator.serviceWorker.register('/service-worker.js');
	});

	$effect(() => {
		const isOpeningGame = /^\/app\/games\/[^/]+$/.test(navigating?.to?.url.pathname ?? '');
		if (isOpeningGame) {
			if (!showGameNavigationLoader) {
				gameNavigationStartedAt = Date.now();
				showGameNavigationLoader = true;
			}
			return;
		}

		if (!showGameNavigationLoader) return;

		const remainingDuration = CARD_SHUFFLE_MIN_DURATION_MS - (Date.now() - gameNavigationStartedAt);
		const timeout = setTimeout(
			() => (showGameNavigationLoader = false),
			Math.max(0, remainingDuration)
		);
		return () => clearTimeout(timeout);
	});
</script>

<svelte:head><link rel="icon" href="/favicon.svg" type="image/svg+xml" /></svelte:head>
<ModeWatcher />
{@render children()}
{#if showGameNavigationLoader}
	<CardShuffleLoading message="Spiel wird geöffnet" />
{/if}
