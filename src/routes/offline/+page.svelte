<script lang="ts">
	import { onMount } from 'svelte';
	import {
		ArrowLeft,
		CheckCircle2,
		Minus,
		Plus,
		Spade,
		Trash2,
		Trophy,
		Undo2,
		Users,
		X
	} from '@lucide/svelte';
	import { resolve } from '$app/paths';
	import SiteHeader from '$lib/components/site-header.svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';
	import { pointActionGroups, type PointAction } from '$lib/game/point-actions';
	import {
		applyLocalEvent,
		createLocalGame,
		loadLocalGames,
		saveLocalGames,
		undoLocalEvent,
		type LocalGames
	} from '$lib/game/local-game';

	let games = $state<LocalGames>({});
	let selectedGameId = $state<string | null>(null);
	let setupOpen = $state(false);
	let playerCount = $state(2);
	let playerNames = $state(['', '']);
	let startingPoints = $state(7);
	let selectedTeamId = $state<string | null>(null);
	let selectedAction = $state<PointAction | null>(null);
	let spritz = $state(false);
	let scoreSheetOpen = $state(false);
	let message = $state('');
	let ready = $state(false);
	let activeGame = $derived(selectedGameId ? games[selectedGameId] : undefined);
	let activeRound = $derived(activeGame?.rounds.find((round) => round.status === 'active'));
	let completedRounds = $derived(
		activeGame?.rounds.filter((round) => round.status === 'completed').reverse() ?? []
	);
	let actions = $derived(
		pointActionGroups.flatMap((group) =>
			group.actions.filter(
				(action) => activeGame && action.availablePlayerCounts.includes(activeGame.playerCount)
			)
		)
	);

	onMount(() => {
		games = loadLocalGames();
		selectedGameId = new URLSearchParams(window.location.search).get('game');
		if (!selectedGameId || !games[selectedGameId]) selectedGameId = null;
		ready = true;
	});

	$effect(() => {
		if (ready) saveLocalGames(games);
	});

	$effect(() => {
		if (activeGame && !selectedTeamId) selectedTeamId = activeGame.teams[0]?.id ?? null;
		if (!activeGame) selectedTeamId = null;
	});

	function setPlayerCount(count: number) {
		playerCount = count;
		playerNames = Array.from({ length: count }, (_, index) => playerNames[index] ?? '');
		startingPoints = count === 2 ? 7 : 24;
	}

	function openGame(id: string) {
		selectedGameId = id;
		setupOpen = false;
		message = '';
		window.history.replaceState({}, '', `/offline?game=${id}`);
	}

	function closeGame() {
		selectedGameId = null;
		selectedAction = null;
		message = '';
		window.history.replaceState({}, '', '/offline');
	}

	function createGame() {
		const names = playerNames.map((name) => name.trim());
		if (names.some((name) => !name)) {
			message = 'Bitte gib für jeden Spieler einen Namen ein.';
			return;
		}
		const game = createLocalGame(names, startingPoints);
		games = { ...games, [game.id]: game };
		openGame(game.id);
	}

	function scoreFor(teamId: string) {
		return activeRound?.scores[teamId] ?? activeGame?.startingPoints ?? 0;
	}

	function applyScore(mode: 'wins' | 'loses') {
		if (!activeGame || !selectedTeamId || !selectedAction) return;
		games = {
			...games,
			[activeGame.id]: applyLocalEvent(
				activeGame,
				selectedTeamId,
				selectedAction.title,
				selectedAction.points,
				mode,
				spritz
			)
		};
		message = 'Punkte gespeichert.';
		selectedAction = null;
		spritz = false;
	}

	function undo() {
		if (!activeGame) return;
		const previous = undoLocalEvent(activeGame);
		if (!previous) return;
		games = { ...games, [activeGame.id]: previous };
		message = 'Die letzte Aktion wurde zurückgenommen.';
	}

	function deleteGame(id: string) {
		const remaining = { ...games };
		delete remaining[id];
		games = remaining;
		if (selectedGameId === id) closeGame();
	}

	function resetScoreForm() {
		spritz = false;
		selectedAction = null;
	}

	function pointActionClass(action: PointAction) {
		const selected = selectedAction?.title === action.title;
		const compact = action.title === String(action.points);
		const size = compact ? 'min-h-12' : action.title.length <= 12 ? 'min-h-16' : 'min-h-20';
		return `inline-flex w-fit max-w-full flex-col items-center justify-center rounded-xl px-3 py-2.5 text-center font-bold ${size} ${selected ? 'border-2 border-primary bg-primary/10 text-primary' : 'border border-[#d8b9a3] bg-[#fffdf9] text-[#a8542f] transition hover:-translate-y-0.5 hover:border-primary dark:border-[#6c4e3d] dark:bg-[#49392f] dark:text-[#efbd92]'}`;
	}

	function bummerlTeamNames(round: (typeof completedRounds)[number]) {
		if (!round.winnerTeamId) return 'nicht erfasst';
		const otherTeams = activeGame?.teams.filter((team) => team.id !== round.winnerTeamId) ?? [];
		const highestScore = Math.max(...otherTeams.map((team) => round.scores[team.id]));
		return otherTeams
			.filter((team) => round.scores[team.id] === highestScore)
			.map((team) => team.name)
			.join(', ');
	}
</script>

<svelte:head>
	<title>Meine Spiele | bummerl</title>
	<meta name="description" content="Der digitale Zählblock für eure Schnapsen-Runden." />
</svelte:head>

<SiteHeader />

<main class="mx-auto max-w-5xl px-4 py-6 sm:px-8 sm:py-12">
	{#if !activeGame}
		<div class="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
			<div>
				<p class="text-xs font-bold tracking-[0.16em] text-primary uppercase">Dein Spieltisch</p>
				<h1
					class="mt-2 font-serif text-4xl font-semibold text-[#123d35] sm:text-5xl dark:text-[#f5f0e5]"
				>
					Meine Spiele
				</h1>
				<p class="mt-3 max-w-xl text-muted-foreground">Welche Runde darf weitergehen?</p>
			</div>
			<Button onclick={() => (setupOpen = true)}><Plus size={18} /> Neues Spiel</Button>
		</div>

		{#if setupOpen}
			<Card class="mt-7 p-5 sm:p-8">
				<div class="flex items-start gap-3">
					<Users class="mt-1 text-primary" size={22} />
					<div>
						<h2 class="font-serif text-2xl font-semibold">Wer sitzt am Tisch?</h2>
						<p class="mt-1 text-sm text-muted-foreground">
							Die Spieleranzahl bleibt nach dem Erstellen unverändert.
						</p>
					</div>
				</div>
				<div class="mt-6 grid grid-cols-3 gap-2">
					{#each [2, 3, 4] as count (count)}
						<button
							type="button"
							class={count === playerCount
								? 'min-h-11 rounded-xl border-2 border-primary bg-primary/10 font-bold text-primary'
								: 'min-h-11 rounded-xl border border-border font-semibold'}
							onclick={() => setPlayerCount(count)}>{count} Spieler</button
						>
					{/each}
				</div>
				<div class="mt-5 grid gap-3 sm:grid-cols-2">
					{#each playerNames as name, index (index)}
						<label
							><span
								class="mb-1 block text-xs font-bold tracking-wide text-muted-foreground uppercase"
								>Spieler {index + 1}</span
							><input
								bind:value={playerNames[index]}
								aria-label={name ? `Name von ${name}` : `Name von Spieler ${index + 1}`}
								maxlength="80"
								placeholder={`Name von Spieler ${index + 1}`}
								class="min-h-11 w-full rounded-xl border border-border bg-background px-3"
							/></label
						>
					{/each}
				</div>
				<label class="mt-5 block"
					><span class="mb-1 block text-sm font-bold">Startpunkte</span><input
						bind:value={startingPoints}
						type="number"
						min="1"
						max="999"
						class="min-h-11 w-28 rounded-xl border border-border bg-background px-3 text-center font-bold"
					/></label
				>
				{#if message}<p class="mt-4 text-sm font-semibold text-[#a8542f]">{message}</p>{/if}
				<div class="mt-6 flex flex-wrap gap-3">
					<Button onclick={createGame}>Spiel erstellen <Spade size={17} /></Button><Button
						variant="ghost"
						onclick={() => (setupOpen = false)}>Abbrechen</Button
					>
				</div>
			</Card>
		{/if}

		{#if Object.values(games).length > 0}
			<div class="mt-8 grid gap-4 sm:grid-cols-2">
				{#each Object.values(games).sort( (a, b) => b.updatedAt.localeCompare(a.updatedAt) ) as game (game.id)}
					<Card class="p-5"
						><button class="w-full text-left" onclick={() => openGame(game.id)}
							><p class="text-xs font-bold tracking-[0.14em] text-primary uppercase">
								{game.playerCount} Spieler · {game.startingPoints} Punkte
							</p>
							<h2 class="mt-2 font-serif text-2xl font-semibold">
								{game.teams.map((team) => team.name).join(' · ')}
							</h2>
							<p class="mt-3 text-sm text-muted-foreground">Runde {game.rounds.length}</p></button
						><button
							class="mt-4 inline-flex min-h-11 items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-[#a8542f]"
							onclick={() => deleteGame(game.id)}><Trash2 size={16} /> Löschen</button
						></Card
					>
				{/each}
			</div>
		{:else if !setupOpen}
			<Card class="mt-8 border-dashed p-10 text-center"
				><Spade class="mx-auto text-primary" size={28} />
				<h2 class="mt-4 font-serif text-2xl font-semibold">Der Tisch ist noch frei.</h2>
				<p class="mt-2 text-sm text-muted-foreground">
					Erstelle dein erstes Spiel, trage die Namen ein und überlass das Rechnen ab jetzt bummerl.
				</p></Card
			>
		{/if}
	{:else}
		<a
			href={resolve('/offline')}
			class="inline-flex min-h-10 items-center gap-2 text-xs font-semibold text-muted-foreground transition hover:text-primary sm:text-sm"
			onclick={(event) => {
				event.preventDefault();
				closeGame();
			}}><ArrowLeft size={16} /> Zurück zu meinen Spielen</a
		>
		<div class="mt-4 flex flex-col justify-between gap-3 sm:mt-7 sm:flex-row sm:items-end">
			<div class="min-w-0">
				<p class="text-xs font-bold tracking-[0.16em] text-primary uppercase sm:text-sm">
					Dein Spiel
				</p>
				<h1
					class="mt-1 truncate font-serif text-2xl font-semibold tracking-tight text-[#123d35] sm:mt-2 sm:text-5xl dark:text-[#f5f0e5]"
				>
					{activeGame.teams.map((team) => team.name).join(' · ')}
				</h1>
			</div>
			<div
				class="rounded-full bg-[#e6eee4] px-3 py-1.5 text-xs font-bold text-[#277150] sm:px-4 sm:py-2 sm:text-sm dark:bg-[#21443b] dark:text-[#a8d8bc]"
			>
				Runde {activeRound?.number}
			</div>
		</div>
		{#if message}<div
				class="mt-4 flex items-start gap-2 rounded-xl border border-[#b6d0bb] bg-[#eaf4eb] px-3 py-2 text-xs leading-5 text-[#2c6c43] sm:mt-6 sm:gap-3 sm:px-4 sm:py-3 sm:text-sm sm:leading-6 dark:border-[#31574b] dark:bg-[#21443b] dark:text-[#b4d3bf]"
			>
				<CheckCircle2 size={15} class="mt-0.5 shrink-0 sm:size-[18px]" />{message}
			</div>{/if}
		<Card class="mt-5 overflow-hidden sm:mt-10"
			><div
				class="hidden border-b border-border bg-[#f5f0e5] px-3 py-3 sm:block sm:px-8 sm:py-4 dark:bg-[#21443b]"
			>
				<p
					class="text-[0.65rem] font-bold tracking-[0.12em] text-[#6b7c70] uppercase sm:text-sm sm:tracking-[0.14em] dark:text-[#b4c4bc]"
				>
					Punktetabelle · Runde {activeRound?.number}
				</p>
			</div>
			<div class="overflow-x-auto">
				<table class="w-full table-fixed border-collapse text-left">
					<thead
						><tr
							class="border-b border-border text-xs font-bold tracking-[0.14em] text-muted-foreground uppercase"
							>{#each activeGame.teams as team, index (team.id)}<th
									class="px-1 py-3 text-center text-[0.65rem] leading-tight break-words sm:px-4 sm:py-5 sm:text-xs sm:tracking-[0.14em]"
									>{#if activeGame.playerCount === 4}<span
											class="block text-[0.55rem] tracking-normal text-muted-foreground sm:text-xs"
											>Team {index + 1}</span
										>{/if}<span class="mt-0.5 block">{team.name}</span><span
										class="mt-0.5 block min-h-3 text-[0.6rem] text-primary sm:mt-1 sm:min-h-4 sm:text-base"
										>{'• '.repeat(team.bummerlCount)}</span
									></th
								>{/each}</tr
						></thead
					><tbody
						>{#each activeRound?.events ?? [] as event (event.id)}<tr
								class="border-b border-border/50 last:border-0"
								>{#each activeGame.teams as team (team.id)}<td
										class={event.targetTeamIds.includes(team.id)
											? 'px-1 py-3 text-center text-sm font-semibold text-primary sm:px-4 sm:py-4 sm:text-base'
											: 'px-1 py-3 text-center text-sm font-semibold text-muted-foreground/40 sm:px-4 sm:py-4 sm:text-base'}
										>{event.targetTeamIds.includes(team.id) ? event.points : '—'}</td
									>{/each}</tr
							>{/each}</tbody
					><tfoot
						><tr class="border-t-4 border-primary bg-[#123d35] dark:bg-[#0f2521]"
							>{#each activeGame.teams as team (team.id)}<td
									class="px-1 py-4 text-center font-serif text-3xl font-semibold text-[#fffaf2] sm:px-4 sm:py-5 sm:text-5xl"
									>{scoreFor(team.id)}</td
								>{/each}</tr
						></tfoot
					>
				</table>
			</div></Card
		>
		{#snippet roundEntry()}<div>
				<div class="flex items-start justify-between gap-4">
					<div>
						<p class="text-xs font-bold tracking-[0.15em] text-primary uppercase">
							Punkte eintragen
						</p>
						<h2 class="mt-1 font-serif text-3xl font-semibold">Wie war die Runde?</h2>
						<p class="mt-2 text-sm leading-6 text-muted-foreground">
							Wähle {activeGame.playerCount === 4 ? 'ein Team' : 'einen Spieler'} und die Punktaktion,
							danach das Ergebnis.
						</p>
					</div>
					<Minus size={22} class="mt-1 text-primary" />
				</div>
				<div class="mt-6 pb-20 sm:pb-0">
					<div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
						{#each activeGame.teams as team, index (team.id)}<button
								type="button"
								aria-pressed={selectedTeamId === team.id}
								class={selectedTeamId === team.id
									? 'min-h-16 rounded-xl border-2 border-primary bg-primary/10 px-3 py-3 text-left text-primary shadow-sm'
									: 'min-h-16 rounded-xl border border-border bg-background px-3 py-3 text-left text-foreground transition hover:border-primary/50'}
								onclick={() => (selectedTeamId = team.id)}
								>{#if activeGame.playerCount === 4}<span
										class="block text-xs font-semibold text-primary">Team {index + 1}</span
									>{/if}<span class="mt-1 block truncate text-sm font-bold">{team.name}</span><span
									class="mt-1 block text-xs font-medium text-muted-foreground"
									>{scoreFor(team.id)} Punkte</span
								></button
							>{/each}
					</div>
					<div class="mt-5 space-y-4">
						<div class="flex flex-wrap items-stretch gap-2">
							{#each actions as action (action.title)}<button
									type="button"
									aria-pressed={selectedAction?.title === action.title}
									class={pointActionClass(action)}
									onclick={() => (selectedAction = action)}
									><span class="block text-sm leading-tight break-words whitespace-normal"
										>{action.title}</span
									><span class="mt-1.5 block text-xs font-semibold opacity-75"
										>{Math.abs(action.points)} Punkte</span
									></button
								>{/each}
						</div>
					</div>
					{#if activeGame.playerCount > 2}<label
							class="mt-5 inline-flex min-h-12 w-fit max-w-full cursor-pointer items-center gap-3 rounded-xl border border-border bg-background px-3 py-2 transition hover:border-primary/50"
							><input
								type="checkbox"
								bind:checked={spritz}
								class="size-5 shrink-0 accent-[#d97745]"
							/><span
								><span class="block text-sm font-bold text-foreground">Gspritzt</span><span
									class="block text-xs text-muted-foreground">Punktabzug wird verdoppelt</span
								></span
							></label
						>{/if}
					<div class="mt-5 hidden grid-cols-2 gap-2 sm:grid sm:max-w-md">
						<button
							disabled={!selectedAction}
							class="min-h-14 rounded-xl bg-[#2f8b59] px-4 text-sm font-bold text-white shadow-sm transition hover:bg-[#267349] disabled:pointer-events-none disabled:opacity-50"
							onclick={() => {
								applyScore('wins');
								resetScoreForm();
								scoreSheetOpen = false;
							}}>Gewonnen</button
						><button
							disabled={!selectedAction}
							class="min-h-14 rounded-xl bg-[#c96638] px-4 text-sm font-bold text-white shadow-sm transition hover:bg-[#b8562d] disabled:pointer-events-none disabled:opacity-50"
							onclick={() => {
								applyScore('loses');
								resetScoreForm();
								scoreSheetOpen = false;
							}}>Verloren</button
						>
					</div>
					<div class="fixed right-4 bottom-4 left-4 z-[60] grid grid-cols-2 gap-2 sm:hidden">
						<button
							disabled={!selectedAction}
							class="min-h-14 rounded-full bg-[#2f8b59] px-3 text-sm font-bold text-white shadow-[0_12px_30px_rgb(28_91_54_/_0.3)] disabled:pointer-events-none disabled:opacity-50"
							onclick={() => {
								applyScore('wins');
								resetScoreForm();
								scoreSheetOpen = false;
							}}>Gewonnen</button
						><button
							disabled={!selectedAction}
							class="min-h-14 rounded-full bg-[#c96638] px-3 text-sm font-bold text-white shadow-[0_12px_30px_rgb(80_45_25_/_0.28)] disabled:pointer-events-none disabled:opacity-50"
							onclick={() => {
								applyScore('loses');
								resetScoreForm();
								scoreSheetOpen = false;
							}}>Verloren</button
						>
					</div>
				</div>
			</div>{/snippet}
		<div class="hidden md:block"><Card class="mt-6 p-5 sm:p-7">{@render roundEntry()}</Card></div>
		<button
			type="button"
			class="fixed right-4 bottom-4 z-40 inline-flex min-h-14 items-center gap-2 rounded-full bg-primary px-5 text-sm font-bold text-primary-foreground shadow-[0_12px_30px_rgb(80_45_25_/_0.28)] md:hidden"
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
							Runde {activeRound?.number}
						</p>
						<button
							type="button"
							class="inline-flex size-11 items-center justify-center rounded-full text-muted-foreground hover:bg-muted hover:text-foreground"
							onclick={() => (scoreSheetOpen = false)}
							aria-label="Punkteingabe schließen"><X size={20} /></button
						>
					</div>
					<Card class="p-4">{@render roundEntry()}</Card>
				</div>
			</div>{/if}
		{#if activeGame.undoStates.length > 0}<Button
				variant="secondary"
				class="mt-5 w-full sm:w-auto"
				onclick={undo}><Undo2 size={17} /> Letzte Aktion zurücknehmen</Button
			>{/if}
		{#if completedRounds.length > 0}<section class="mt-10">
				<div class="flex items-center gap-3">
					<Trophy size={20} class="text-primary" />
					<h2 class="font-serif text-3xl font-semibold">Bisherige Runden</h2>
				</div>
				<div class="mt-4 grid gap-3 sm:grid-cols-2">
					{#each completedRounds as round (round.id)}<Card class="p-5"
							><p class="text-xs font-bold tracking-[0.14em] text-primary uppercase">
								Runde {round.number}
							</p>
							<p class="mt-2 text-lg font-semibold">
								{activeGame.teams.find((team) => team.id === round.winnerTeamId)?.name} hat gewonnen
							</p>
							<p class="mt-1 text-sm text-muted-foreground">
								Bummerl: {bummerlTeamNames(round)}
							</p></Card
						>{/each}
				</div>
			</section>{/if}
	{/if}
</main>
