<script lang="ts">
	import { Activity, ArrowRight, Clock3, Plus, Sparkles, Trash2 } from '@lucide/svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';
	import { gameTitle, type Game, type GameMode } from '$lib/game/model';

	let {
		games,
		mode,
		userName = '',
		onOpen,
		onCreate,
		onArchive
	}: {
		games: Game[];
		mode: GameMode;
		userName?: string;
		onOpen: (gameId: string) => void;
		onCreate: () => void;
		onArchive: (gameId: string) => Promise<void>;
	} = $props();
	let archivingGameId = $state<string | null>(null);

	function relativeTime(timestamp: string) {
		const minutes = Math.floor((Date.now() - new Date(timestamp).getTime()) / 60000);
		if (minutes < 1) return 'gerade eben';
		if (minutes < 60) return `vor ${minutes} Min.`;
		const hours = Math.floor(minutes / 60);
		return hours < 24 ? `vor ${hours} Std.` : `vor ${Math.floor(hours / 24)} Tagen`;
	}

	async function archive(gameId: string) {
		archivingGameId = gameId;
		try {
			await onArchive(gameId);
		} finally {
			archivingGameId = null;
		}
	}
</script>

<main class="mx-auto max-w-6xl px-5 py-10 sm:px-8 sm:py-14">
	<div class="flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
		<div>
			<p class="text-sm font-bold tracking-[0.16em] text-primary uppercase">Dein Spieltisch</p>
			<h1
				class="mt-2 font-serif text-4xl font-semibold tracking-tight text-[#123d35] sm:text-5xl dark:text-[#f5f0e5]"
			>
				{userName ? `Servus, ${userName}.` : 'Meine Spiele'}
			</h1>
			<p class="mt-3 text-lg text-muted-foreground">Welche Runde darf weitergehen?</p>
		</div>
		<Button onclick={onCreate}><Plus size={18} /> Neues Spiel</Button>
	</div>
	{#if mode === 'offline'}
		<p class="mt-4 text-sm text-muted-foreground">Wird nur auf diesem Gerät gespeichert.</p>
	{/if}

	{#if games.length > 0}
		<div class="mt-10 grid gap-5 sm:grid-cols-2">
			{#each games as game (game.id)}
				<div class="group relative">
					<Card
						class="h-full p-6 transition group-hover:-translate-y-1 group-hover:border-primary/50"
					>
						<button type="button" class="block w-full text-left" onclick={() => onOpen(game.id)}>
							<div class="flex items-start justify-between gap-4">
								<div>
									<p class="text-xs font-bold tracking-[0.15em] text-primary uppercase">
										{game.playerCount} Spieler · {game.startingPoints} Punkte
									</p>
									<h2 class="mt-3 font-serif text-2xl font-semibold">{gameTitle(game)}</h2>
								</div>
								<ArrowRight
									size={19}
									class="mt-1 text-muted-foreground transition group-hover:translate-x-1 group-hover:text-primary"
								/>
							</div>
						</button>
						<div class="mt-6 flex items-end gap-3 border-t border-border/70 pt-4">
							<div class="grid min-w-0 flex-1 grid-cols-2 gap-3">
								<div class="flex min-w-0 items-start gap-2">
									<Clock3 size={16} class="mt-0.5 shrink-0 text-primary" />
									<div class="min-w-0">
										<span
											class="block text-[0.65rem] font-bold tracking-[0.12em] text-muted-foreground uppercase"
											>Gestartet</span
										><time class="mt-1 block truncate text-sm font-semibold"
											>{relativeTime(game.startedAt)}</time
										>
									</div>
								</div>
								<div class="flex min-w-0 items-start gap-2">
									<Activity size={16} class="mt-0.5 shrink-0 text-primary" />
									<div class="min-w-0">
										<span
											class="block text-[0.65rem] font-bold tracking-[0.12em] text-muted-foreground uppercase"
											>Letzte Aktion</span
										><time class="mt-1 block truncate text-sm font-semibold"
											>{relativeTime(game.lastEventAt)}</time
										>
									</div>
								</div>
							</div>
							<button
								type="button"
								disabled={archivingGameId === game.id}
								class="inline-flex size-11 items-center justify-center rounded-lg text-muted-foreground transition hover:bg-[#fff0e8] hover:text-[#a8542f]"
								onclick={() => archive(game.id)}
								aria-label={mode === 'offline' ? 'Spiel löschen' : 'Spiel archivieren'}
								>{#if archivingGameId === game.id}…{:else}<Trash2 size={17} />{/if}</button
							>
						</div>
					</Card>
				</div>
			{/each}
		</div>
	{:else}
		<Card class="mt-10 border-dashed bg-card/60"
			><div class="flex flex-col items-center px-6 py-16 text-center sm:px-10">
				<div
					class="flex size-16 items-center justify-center rounded-2xl bg-[#e8eee5] text-[#347258] dark:bg-[#21443b] dark:text-[#b4d3bf]"
				>
					<Sparkles size={27} />
				</div>
				<h2 class="mt-6 font-serif text-3xl font-semibold">Der Tisch ist noch frei.</h2>
				<p class="mt-3 max-w-md leading-7 text-muted-foreground">
					Erstelle dein erstes Spiel, trage die Namen ein und überlass das Rechnen ab jetzt bummerl.
				</p>
				<Button variant="secondary" class="mt-7" onclick={onCreate}
					><Plus size={17} /> Erstes Spiel anlegen</Button
				>
			</div></Card
		>
	{/if}
</main>
