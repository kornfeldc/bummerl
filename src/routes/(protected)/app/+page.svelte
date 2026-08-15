<script lang="ts">
	import { enhance } from '$app/forms';
	import { Activity, Archive, ArrowRight, Clock3, Plus, Sparkles, Trash2 } from '@lucide/svelte';
	import { resolve } from '$app/paths';
	import LoadingDots from '$lib/components/loading-dots.svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';

	let { data } = $props();
	let archivingGameId = $state<string | null>(null);

	function relativeTime(timestamp: string) {
		const elapsedMinutes = Math.floor((Date.now() - new Date(timestamp).getTime()) / 60000);
		if (elapsedMinutes < 1) return 'gerade eben';
		if (elapsedMinutes < 60) return `vor ${elapsedMinutes} Min.`;
		const elapsedHours = Math.floor(elapsedMinutes / 60);
		if (elapsedHours < 24) return `vor ${elapsedHours} Std.`;
		const elapsedDays = Math.floor(elapsedHours / 24);
		if (elapsedDays < 7) return `vor ${elapsedDays} Tagen`;
		return `vor ${Math.floor(elapsedDays / 7)} Wo.`;
	}

	function absoluteTime(timestamp: string) {
		return new Intl.DateTimeFormat('de-AT', {
			dateStyle: 'medium',
			timeStyle: 'short'
		}).format(new Date(timestamp));
	}

	function archiveSubmit(gameId: string) {
		return () => {
			archivingGameId = gameId;
			return async ({ update }: { update: () => Promise<void> }) => {
				try {
					await update();
				} finally {
					archivingGameId = null;
				}
			};
		};
	}
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
				<div class="group relative">
					<Card
						class="h-full p-6 transition group-hover:-translate-y-1 group-hover:border-primary/50"
					>
						<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -->
						<a href={`${resolve('/app')}/games/${game.id}`} class="block">
							<div class="flex items-start justify-between gap-4">
								<div>
									<p class="text-xs font-bold tracking-[0.15em] text-primary uppercase">
										{game.player_count} Spieler · {game.starting_points} Punkte
									</p>
									<h2 class="mt-3 font-serif text-2xl font-semibold">
										{game.game_teams
											.slice()
											.sort((left, right) => left.team_order - right.team_order)
											.map((team) => team.game_players.map((player) => player.name).join(' + '))
											.join(' · ')}
									</h2>
								</div>
								<ArrowRight
									size={19}
									class="mt-1 text-muted-foreground transition group-hover:translate-x-1 group-hover:text-primary"
								/>
							</div>
						</a>
						<div class="mt-6 flex items-end gap-3 border-t border-border/70 pt-4">
							<div class="grid min-w-0 flex-1 grid-cols-2 gap-3">
								<div class="flex min-w-0 items-start gap-2">
									<Clock3 size={16} class="mt-0.5 shrink-0 text-primary" />
									<div class="min-w-0">
										<span
											class="block text-[0.65rem] font-bold tracking-[0.12em] text-muted-foreground uppercase"
											>Gestartet</span
										>
										<time
											class="mt-1 block truncate text-sm font-semibold text-foreground"
											datetime={game.started_at}
											title={absoluteTime(game.started_at)}>{relativeTime(game.started_at)}</time
										>
									</div>
								</div>
								<div class="flex min-w-0 items-start gap-2">
									<Activity size={16} class="mt-0.5 shrink-0 text-primary" />
									<div class="min-w-0">
										<span
											class="block text-[0.65rem] font-bold tracking-[0.12em] text-muted-foreground uppercase"
											>Letzte Aktion</span
										>
										<time
											class="mt-1 block truncate text-sm font-semibold text-foreground"
											datetime={game.last_event_at}
											title={absoluteTime(game.last_event_at)}
											>{relativeTime(game.last_event_at)}</time
										>
									</div>
								</div>
							</div>
							<form
								method="POST"
								action="?/archive"
								use:enhance={archiveSubmit(game.id)}
								class="shrink-0"
							>
								<input type="hidden" name="gameId" value={game.id} />
								<button
									type="submit"
									disabled={archivingGameId === game.id}
									class="inline-flex size-11 items-center justify-center rounded-lg text-muted-foreground transition hover:bg-[#fff0e8] hover:text-[#a8542f] focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none dark:hover:bg-[#3f3327] dark:hover:text-[#efbd92]"
									aria-label="Spiel archivieren"
									title="Spiel archivieren"
								>
									{#if archivingGameId === game.id}<LoadingDots />{:else}<Trash2 size={17} />{/if}
								</button>
							</form>
						</div>
					</Card>
				</div>
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
