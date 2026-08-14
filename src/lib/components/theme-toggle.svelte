<script lang="ts">
	import { Monitor, Moon, Sun } from '@lucide/svelte';
	import { mode, toggleMode } from 'mode-watcher';

	const modeLabel = $derived(
		mode.current === 'dark' ? 'Helles Design aktivieren' : 'Dunkles Design aktivieren'
	);
</script>

<button
	type="button"
	class="inline-flex min-h-10 items-center gap-2 rounded-full border border-border bg-card/70 px-3.5 text-sm font-medium text-foreground transition hover:border-primary/50 hover:bg-card focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
	aria-label={modeLabel}
	onclick={toggleMode}
>
	{#if mode.current === 'dark'}
		<Sun size={16} strokeWidth={2.2} />
	{:else if mode.current === 'light'}
		<Moon size={16} strokeWidth={2.2} />
	{:else}
		<Monitor size={16} strokeWidth={2.2} />
	{/if}
	<span class="hidden sm:inline">Design</span>
</button>
