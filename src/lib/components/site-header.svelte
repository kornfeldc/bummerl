<script lang="ts">
	import { LogOut, Spade } from '@lucide/svelte';
	import { resolve } from '$app/paths';
	import { Button } from '$lib/components/ui/button';
	import ThemeToggle from '$lib/components/theme-toggle.svelte';

	let { authenticated = false, userName = '' }: { authenticated?: boolean; userName?: string } =
		$props();
</script>

<header class="relative z-10 border-b border-white/10 bg-[#123d35]/95 text-[#fffaf2] backdrop-blur">
	<div class="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-5 py-4 sm:px-8">
		<a href={resolve('/')} class="group flex items-center gap-3" aria-label="Bummerl Startseite">
			<span
				class="flex size-10 items-center justify-center rounded-xl bg-[#e58b58] text-[#18352e] shadow-lg transition group-hover:rotate-6"
			>
				<Spade size={21} fill="currentColor" strokeWidth={2.5} />
			</span>
			<span>
				<strong class="block font-serif text-xl leading-none tracking-tight">bummerl</strong>
				<span class="text-[0.65rem] font-medium tracking-[0.2em] text-[#b8d1c3] uppercase"
					>Schnapsen zählen</span
				>
			</span>
		</a>

		<div class="flex items-center gap-2 sm:gap-3">
			<ThemeToggle />
			{#if authenticated}
				<form method="POST" action="/auth/logout">
					<Button
						type="submit"
						variant="ghost"
						class="border border-white/15 text-[#fffaf2] hover:bg-white/10 hover:text-white"
					>
						<LogOut size={16} />
						<span class="hidden sm:inline">Abmelden</span>
					</Button>
				</form>
			{:else}
				<a
					href={resolve('/login')}
					class="rounded-full px-4 py-2 text-sm font-semibold text-[#fffaf2] transition hover:bg-white/10"
					>Anmelden</a
				>
			{/if}
		</div>
	</div>
	{#if authenticated && userName}
		<div class="mx-auto hidden max-w-6xl px-8 pb-2 text-right text-xs text-[#b8d1c3] sm:block">
			Angemeldet als {userName}
		</div>
	{/if}
</header>
