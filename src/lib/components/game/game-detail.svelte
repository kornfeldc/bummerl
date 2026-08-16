<script lang="ts">
	import { tick } from 'svelte';
	import {
		ArrowLeft,
		CheckCircle2,
		CircleDot,
		Minus,
		Spade,
		Trophy,
		Undo2,
		X
	} from '@lucide/svelte';
	import CardShuffleLoading from '$lib/components/card-shuffle-loading.svelte';
	import RoundOverview from '$lib/components/game/round-overview.svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';
	import { CARD_SHUFFLE_MIN_DURATION_MS } from '$lib/loading';
	import { pointActionGroups, type PointAction } from '$lib/game/point-actions';
	import { gameTitle, type Game, type GameRepository, type GameRound } from '$lib/game/model';

	let { game, repository, onBack }: { game: Game; repository: GameRepository; onBack: () => void } =
		$props();
	let selectedTeamId = $state<string | null>(null);
	let selectedAction = $state<PointAction | null>(null);
	let spritz = $state(false);
	let scoreSheetOpen = $state(false);
	let roundOverviewId = $state<string | null>(null);
	let busy = $state(false);
	let message = $state('');
	const teams = $derived(game.teams.slice().sort((a, b) => a.order - b.order));
	const activeRound = $derived(game.rounds.find((round) => round.status === 'active'));
	const completedRounds = $derived(
		game.rounds
			.filter((round) => round.status === 'completed')
			.slice()
			.reverse()
	);
	const overviewRound = $derived(
		roundOverviewId ? game.rounds.find((round) => round.id === roundOverviewId) : undefined
	);
	const hasScoreEvents = $derived(game.rounds.some((round) => round.events.length > 0));
	const actionGroups = $derived(
		pointActionGroups
			.map((group) => ({
				...group,
				actions: group.actions.filter((action) =>
					action.availablePlayerCounts.includes(game.playerCount)
				)
			}))
			.filter((group) => group.actions.length)
	);
	$effect(() => {
		if (!selectedTeamId && teams[0]) selectedTeamId = teams[0].id;
	});
	function scoreFor(teamId: string, round = activeRound) {
		return round?.scores[teamId] ?? game.startingPoints;
	}
	function teamName(teamId: string | null) {
		return teams.find((team) => team.id === teamId)?.name ?? 'Unbekannt';
	}
	function bummerlTeamNames(round: GameRound) {
		if (!round.winnerTeamId) return 'nicht erfasst';
		const others = teams.filter((team) => team.id !== round.winnerTeamId);
		const highest = Math.max(...others.map((team) => scoreFor(team.id, round)));
		return others
			.filter((team) => scoreFor(team.id, round) === highest)
			.map((team) => team.name)
			.join(', ');
	}
	function actionClass(action: PointAction, key: 'low' | 'medium' | 'high') {
		const selected = selectedAction?.title === action.title;
		const colors =
			key === 'low'
				? 'border-[#d8b9a3] bg-[#fffdf9] text-[#a8542f] dark:border-[#6c4e3d] dark:bg-[#49392f] dark:text-[#efbd92]'
				: key === 'medium'
					? 'border-[#d2a98d] bg-[#fbf0e7] text-[#964725] dark:border-[#795441] dark:bg-[#574034] dark:text-[#f0b28a]'
					: 'border-[#c99372] bg-[#f8e5d7] text-[#843d20] dark:border-[#8e5b40] dark:bg-[#654535] dark:text-[#f4b78e]';
		return `inline-flex min-h-12 w-fit max-w-full flex-col items-center justify-center rounded-xl border px-3 py-2.5 text-center font-bold transition ${selected ? 'border-2 border-primary bg-primary/10 text-primary' : colors}`;
	}
	async function startRound() {
		busy = true;
		try {
			await repository.startRound(game.id);
			message = 'Runde gestartet.';
		} catch (error) {
			message = error instanceof Error ? error.message : 'Die Runde konnte nicht gestartet werden.';
		} finally {
			busy = false;
		}
	}
	async function score(mode: 'wins' | 'loses') {
		if (!activeRound || !selectedTeamId || !selectedAction) return;
		const scoredRoundId = activeRound.id;
		const submittedAt = Date.now();
		let completedRoundId: string | null = null;
		busy = true;
		try {
			await repository.applyEvent({
				gameId: game.id,
				roundId: activeRound.id,
				selectedTeamId,
				title: selectedAction.title,
				points: selectedAction.points,
				mode,
				spritz
			});
			await tick();
			const completedRound = game.rounds.find(
				(round) => round.id === scoredRoundId && round.status === 'completed'
			);
			if (completedRound) {
				completedRoundId = completedRound.id;
				message = 'Runde beendet. Die nächste Runde wurde eröffnet.';
			} else {
				message = 'Punkte gespeichert.';
			}
			selectedAction = null;
			spritz = false;
			scoreSheetOpen = false;
		} catch (error) {
			message =
				error instanceof Error ? error.message : 'Die Punkte konnten nicht gespeichert werden.';
		} finally {
			const remainingDuration = CARD_SHUFFLE_MIN_DURATION_MS - (Date.now() - submittedAt);
			if (remainingDuration > 0) {
				await new Promise((resolve) => setTimeout(resolve, remainingDuration));
			}
			busy = false;
			if (completedRoundId) roundOverviewId = completedRoundId;
		}
	}
	async function undo() {
		busy = true;
		try {
			await repository.undoLastEvent(game.id);
			message = 'Die letzte Punktaktion wurde zurückgenommen.';
		} catch (error) {
			message =
				error instanceof Error ? error.message : 'Die Aktion konnte nicht zurückgenommen werden.';
		} finally {
			busy = false;
		}
	}
</script>

{#if busy}
	<CardShuffleLoading message="Punkte werden eingetragen" />
{/if}

<main class="mx-auto max-w-6xl px-3 py-5 sm:px-8 sm:py-14">
	<button
		type="button"
		class="inline-flex min-h-10 items-center gap-2 text-xs font-semibold text-muted-foreground transition hover:text-primary sm:text-sm"
		onclick={onBack}><ArrowLeft size={16} /> Zurück zu meinen Spielen</button
	>
	<div class="mt-4 flex flex-col justify-between gap-3 sm:mt-7 sm:flex-row sm:items-end">
		<div class="min-w-0">
			<p class="text-xs font-bold tracking-[0.16em] text-primary uppercase sm:text-sm">
				Dein Spiel
			</p>
			<h1
				class="mt-1 truncate font-serif text-2xl font-semibold tracking-tight text-[#123d35] sm:mt-2 sm:text-5xl dark:text-[#f5f0e5]"
			>
				{gameTitle(game)}
			</h1>
		</div>
		{#if activeRound}<div
				class="rounded-full bg-[#e6eee4] px-3 py-1.5 text-xs font-bold text-[#277150] sm:px-4 sm:py-2 sm:text-sm dark:bg-[#21443b] dark:text-[#a8d8bc]"
			>
				Runde {activeRound.number}
			</div>{:else}<Button onclick={startRound} loading={busy}>Runde starten</Button>{/if}
	</div>
	{#if message}<div
			class="mt-4 flex items-start gap-2 rounded-xl border border-[#b6d0bb] bg-[#eaf4eb] px-3 py-2 text-sm text-[#2c6c43] dark:border-[#31574b] dark:bg-[#21443b] dark:text-[#b4d3bf]"
		>
			<CheckCircle2 size={16} class="mt-0.5 shrink-0" />{message}
		</div>{/if}
	<Card class="mt-5 overflow-hidden sm:mt-10"
		><div class="hidden border-b border-border bg-[#f5f0e5] px-8 py-4 sm:block dark:bg-[#21443b]">
			<p class="text-sm font-bold tracking-[0.14em] text-[#6b7c70] uppercase dark:text-[#b4c4bc]">
				{activeRound
					? `Punktetabelle · Runde ${activeRound.number}`
					: 'Punktetabelle · bereit für Runde 1'}
			</p>
		</div>
		<div class="overflow-x-auto">
			<table class="w-full table-fixed border-collapse">
				<thead
					><tr
						class="border-b border-border text-xs font-bold tracking-[0.14em] text-muted-foreground uppercase"
						>{#each teams as team (team.id)}<th
								class="px-1 py-3 text-center leading-tight break-words sm:px-4 sm:py-5"
								>{#if game.playerCount === 4}<span
										class="block text-[0.65rem] text-muted-foreground">Team {team.order}</span
									>{/if}<span class="mt-1 block">{team.name}</span><span
									class="mt-1 block min-h-4 text-primary">{'• '.repeat(team.bummerlCount)}</span
								></th
							>{/each}</tr
					></thead
				><tbody
					>{#if activeRound}{#each activeRound.events as event (event.id)}<tr
								class="border-b border-border/50 last:border-0"
								>{#each teams as team (team.id)}<td
										class={event.targetTeamIds.includes(team.id)
											? 'px-1 py-3 text-center text-sm font-semibold text-primary sm:px-4 sm:py-4 sm:text-base'
											: 'px-1 py-3 text-center text-sm font-semibold text-muted-foreground/40 sm:px-4 sm:py-4 sm:text-base'}
										>{event.targetTeamIds.includes(team.id) ? event.points : '—'}</td
									>{/each}</tr
							>{/each}{/if}</tbody
				>{#if activeRound}<tfoot
						><tr class="border-t-4 border-primary bg-[#123d35] dark:bg-[#0f2521]"
							>{#each teams as team (team.id)}<td
									class={scoreFor(team.id) <= 0
										? 'px-1 py-4 text-center font-serif text-3xl font-semibold text-[#9de0b1] sm:px-4 sm:py-5 sm:text-5xl'
										: 'px-1 py-4 text-center font-serif text-3xl font-semibold text-[#fffaf2] sm:px-4 sm:py-5 sm:text-5xl'}
									>{scoreFor(team.id)}</td
								>{/each}</tr
						></tfoot
					>{/if}
			</table>
		</div>
		{#if !activeRound}<div
				class="flex items-center gap-3 border-t border-border bg-card/60 px-5 py-4 text-sm text-muted-foreground"
			>
				<CircleDot size={16} class="shrink-0 text-primary" /> Starte die erste Runde, sobald die Karten
				ausgeteilt sind.
			</div>{/if}</Card
	>
	{#snippet entry()}<div>
			<div class="flex items-start justify-between gap-4">
				<div>
					<p class="text-xs font-bold tracking-[0.15em] text-primary uppercase">Punkte eintragen</p>
					<h2 class="mt-1 font-serif text-3xl font-semibold">Wie war die Runde?</h2>
					<p class="mt-2 text-sm leading-6 text-muted-foreground">
						Wähle {game.playerCount === 4 ? 'ein Team' : 'einen Spieler'} und die Punktaktion, danach
						das Ergebnis.
					</p>
				</div>
				<Minus size={22} class="mt-1 text-primary" />
			</div>
			<div class="mt-6 pb-20 sm:pb-0">
				<div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
					{#each teams as team (team.id)}<button
							type="button"
							disabled={busy}
							aria-pressed={selectedTeamId === team.id}
							class={selectedTeamId === team.id
								? 'min-h-16 rounded-xl border-2 border-primary bg-primary/10 px-3 py-3 text-left text-primary shadow-sm'
								: 'min-h-16 rounded-xl border border-border bg-background px-3 py-3 text-left transition hover:border-primary/50'}
							onclick={() => (selectedTeamId = team.id)}
							>{#if game.playerCount === 4}<span class="block text-xs font-semibold text-primary"
									>Team {team.order}</span
								>{/if}<span class="mt-1 block truncate text-sm font-bold">{team.name}</span><span
								class="mt-1 block text-xs text-muted-foreground">{scoreFor(team.id)} Punkte</span
							></button
						>{/each}
				</div>
				<div class="mt-5 space-y-4">
					{#each actionGroups as group (group.key)}<div class="flex flex-wrap gap-2">
							{#each group.actions as action (action.title)}<button
									type="button"
									disabled={busy}
									aria-pressed={selectedAction?.title === action.title}
									class={actionClass(action, group.key)}
									onclick={() => (selectedAction = action)}
									><span class="text-sm leading-tight"
										>{action.title === String(action.points)
											? Math.abs(action.points)
											: action.title}</span
									>{#if action.title !== String(action.points)}<span class="mt-1 text-xs opacity-75"
											>{Math.abs(action.points)} Punkte</span
										>{/if}</button
								>{/each}
						</div>{/each}
				</div>
				{#if game.playerCount > 2}<label
						class="mt-5 inline-flex min-h-12 items-center gap-3 rounded-xl border border-border bg-background px-3 py-2"
						><input
							type="checkbox"
							bind:checked={spritz}
							disabled={busy}
							class="size-5 accent-[#d97745]"
						/><span
							><span class="block text-sm font-bold">Gspritzt</span><span
								class="block text-xs text-muted-foreground">Punktabzug wird verdoppelt</span
							></span
						></label
					>{/if}
				<div class="mt-5 hidden grid-cols-2 gap-2 sm:grid sm:max-w-md">
					<button
						disabled={busy || !selectedAction}
						class="min-h-14 rounded-xl bg-[#2f8b59] px-4 text-sm font-bold text-white disabled:opacity-50"
						onclick={() => score('wins')}>Gewonnen</button
					><button
						disabled={busy || !selectedAction}
						class="min-h-14 rounded-xl bg-[#c96638] px-4 text-sm font-bold text-white disabled:opacity-50"
						onclick={() => score('loses')}>Verloren</button
					>
				</div>
				<div class="fixed right-4 bottom-4 left-4 z-[60] grid grid-cols-2 gap-2 sm:hidden">
					<button
						disabled={busy || !selectedAction}
						class="min-h-14 rounded-full bg-[#2f8b59] px-3 text-sm font-bold text-white shadow-lg disabled:opacity-50"
						onclick={() => score('wins')}>Gewonnen</button
					><button
						disabled={busy || !selectedAction}
						class="min-h-14 rounded-full bg-[#c96638] px-3 text-sm font-bold text-white shadow-lg disabled:opacity-50"
						onclick={() => score('loses')}>Verloren</button
					>
				</div>
			</div>
		</div>{/snippet}
	{#if activeRound}<div class="hidden md:block">
			<Card class="mt-6 p-5 sm:p-7">{@render entry()}</Card>
		</div>
		<button
			type="button"
			disabled={busy}
			class="fixed right-4 bottom-4 z-40 inline-flex min-h-14 items-center gap-2 rounded-full bg-primary px-5 text-sm font-bold text-primary-foreground shadow-lg md:hidden"
			onclick={() => (scoreSheetOpen = true)}
			><Spade size={18} fill="currentColor" /> Punkte eintragen</button
		>{#if scoreSheetOpen}<div
				class="fixed inset-0 z-50 overflow-y-auto bg-background px-3 py-3 md:hidden"
				role="dialog"
				aria-modal="true"
				aria-label="Wie war die Runde"
			>
				<div class="mx-auto min-h-full max-w-xl">
					<div class="flex min-h-12 items-center justify-between px-1">
						<p class="text-xs font-bold tracking-[0.14em] text-muted-foreground uppercase">
							Runde {activeRound.number}
						</p>
						<button
							type="button"
							class="inline-flex size-11 items-center justify-center rounded-full text-muted-foreground hover:bg-muted"
							onclick={() => (scoreSheetOpen = false)}
							aria-label="Punkteingabe schließen"><X size={20} /></button
						>
					</div>
					<Card class="p-4">{@render entry()}</Card>
				</div>
			</div>{/if}{/if}
	{#if hasScoreEvents}<Button
			variant="secondary"
			class="mt-5 w-full sm:w-auto"
			onclick={undo}
			loading={busy}><Undo2 size={17} /> Letzte Aktion zurücknehmen</Button
		>{/if}
	{#if completedRounds.length > 0}<section class="mt-10">
			<div class="flex items-center gap-3">
				<Trophy size={20} class="text-primary" />
				<h2 class="font-serif text-3xl font-semibold">Bisherige Runden</h2>
			</div>
			<div class="mt-4 grid gap-3 sm:grid-cols-2">
				{#each completedRounds as round (round.id)}<Card
						class="p-0 transition hover:border-primary/50"
						><button
							type="button"
							class="w-full p-5 text-left"
							onclick={() => (roundOverviewId = round.id)}
							><p class="text-xs font-bold tracking-[0.14em] text-primary uppercase">
								Runde {round.number}
							</p>
							<p class="mt-2 text-lg font-semibold">{teamName(round.winnerTeamId)} hat gewonnen</p>
							<p class="mt-1 text-sm text-muted-foreground">
								Bummerl: {bummerlTeamNames(round)}
							</p></button
						></Card
					>{/each}
			</div>
		</section>{/if}
	{#if overviewRound}
		<RoundOverview {game} round={overviewRound} onClose={() => (roundOverviewId = null)} />
	{/if}
</main>
