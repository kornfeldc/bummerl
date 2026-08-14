<script lang="ts">
	import './layout.css';
	import { ModeWatcher } from 'mode-watcher';

	let { children } = $props();
</script>

<svelte:head><link rel="icon" href="/favicon.svg" type="image/svg+xml" /></svelte:head>
<ModeWatcher themeColors={{ light: '#123d35', dark: '#0f2521' }} />
{@render children()}
