<script lang="ts">
	import { Archive, ArrowRight, Plus, Sparkles } from '@lucide/svelte';
	import { resolve } from '$app/paths';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';

	let { data } = $props();
</script>

<svelte:head>
	<title>Meine Spiele | bummerl</title>
</svelte:head>

<main class="mx-auto max-w-6xl px-5 py-10 sm:px-8 sm:py-14">
	<div class="flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
		<div>
			<p class="text-sm font-bold tracking-[0.16em] text-primary uppercase">Dein Spieltisch</p>
			<h1
				class="mt-2 font-serif text-5xl font-semibold tracking-tight text-[#123d35] dark:text-[#f5f0e5]"
			>
				Servus, {data.user.user_metadata?.first_name ?? 'Spieler'}.
			</h1>
			<p class="mt-3 text-lg text-muted-foreground">Welche Runde darf weitergehen?</p>
		</div>
		<a href={resolve('/app/games/new')}><Button><Plus size={18} /> Neues Spiel</Button></a>
	</div>

	{#if data.games.length > 0}
		<div class="mt-10 grid gap-5 sm:grid-cols-2">
			{#each data.games as game (game.id)}
				<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -->
				<a href={`${resolve('/app')}/games/${game.id}`} class="group">
					<Card
						class="h-full p-6 transition group-hover:-translate-y-1 group-hover:border-primary/50"
					>
						<div class="flex items-start justify-between gap-4">
							<div>
								<p class="text-xs font-bold tracking-[0.15em] text-primary uppercase">
									{game.player_count} Spieler · {game.starting_points} Punkte
								</p>
								<h2 class="mt-3 font-serif text-2xl font-semibold">
									{game.game_players.map((player) => player.name).join(' · ')}
								</h2>
							</div>
							<ArrowRight
								size={19}
								class="mt-1 text-muted-foreground transition group-hover:translate-x-1 group-hover:text-primary"
							/>
						</div>
						<div class="mt-6 flex items-center gap-2 text-sm text-muted-foreground">
							<span class="size-2 rounded-full bg-[#58a678]"></span>Aktives Spiel
						</div>
					</Card>
				</a>
			{/each}
		</div>
	{:else}
		<Card class="mt-10 border-dashed bg-card/60">
			<div class="flex flex-col items-center px-6 py-16 text-center sm:px-10">
				<div
					class="flex size-16 items-center justify-center rounded-2xl bg-[#e8eee5] text-[#347258] dark:bg-[#21443b] dark:text-[#b4d3bf]"
				>
					<Sparkles size={27} />
				</div>
				<h2 class="mt-6 font-serif text-3xl font-semibold">Der Tisch ist noch frei.</h2>
				<p class="mt-3 max-w-md leading-7 text-muted-foreground">
					Erstelle dein erstes Spiel, trage die Namen ein und überlass das Rechnen ab jetzt bummerl.
				</p>
				<a href={resolve('/app/games/new')} class="mt-7"
					><Button variant="secondary"><Plus size={17} /> Erstes Spiel anlegen</Button></a
				>
			</div>
		</Card>
	{/if}

	<div class="mt-10 flex items-center gap-2 text-sm text-muted-foreground">
		<Archive size={16} /> Archivierte Spiele werden hier später gesammelt.
	</div>
</main>
