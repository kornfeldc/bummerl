<script lang="ts">
	import { ArrowLeft, CheckCircle2, CircleDot, Minus, Trophy, Undo2, X } from '@lucide/svelte';
	import { enhance } from '$app/forms';
	import { resolve } from '$app/paths';
	import { pointActionGroups, type PointAction } from '$lib/game/point-actions';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';

	let { data, form } = $props();
	let selectedTeamId = $state<string | null>(null);
	let spritz = $state(false);
	let selectedAction = $state<PointAction | null>(null);
	let scoreSheetOpen = $state(false);
	const teams = $derived([...data.game.game_teams].sort((a, b) => a.team_order - b.team_order));
	const activeRound = $derived(data.rounds.find((round) => round.status === 'active'));
	const completedRounds = $derived(
		data.rounds.filter((round) => round.status === 'completed').reverse()
	);
	const hasScoreEvents = $derived(data.rounds.some((round) => round.round_events.length > 0));
	const selectedTeam = $derived(teams.find((team) => team.id === selectedTeamId));
	const availablePointActionGroups = $derived(
		pointActionGroups
			.map((group) => ({
				...group,
				actions: group.actions.filter((action) =>
					action.availablePlayerCounts.includes(data.game.player_count)
				)
			}))
			.filter((group) => group.actions.length > 0)
	);
	const selectedPoints = $derived(selectedAction ? selectedAction.points * (spritz ? 2 : 1) : 0);

	function scoreFor(teamId: string, round = activeRound) {
		const team = teams.find((candidate) => candidate.id === teamId);
		const playerIds = team?.game_players.map((player) => player.id) ?? [];
		return (
			round?.round_player_scores.find((score) => playerIds.includes(score.player_id))
				?.remaining_points ?? data.game.starting_points
		);
	}

	function teamName(teamId: string | null) {
		const team = teams.find((candidate) => candidate.id === teamId);
		return team?.game_players.map((player) => player.name).join(' + ') ?? 'Unbekannt';
	}

	function gameTitle() {
		return teams
			.map((team) => team.game_players.map((player) => player.name).join(' + '))
			.join(' · ');
	}

	function selectTeam(teamId: string) {
		selectedTeamId = selectedTeamId === teamId ? null : teamId;
	}

	function resetScoreForm() {
		selectedTeamId = null;
		spritz = false;
		selectedAction = null;
	}

	function handleScoreSubmit() {
		return async ({
			result,
			update
		}: {
			result: { type: string };
			update: () => Promise<void>;
		}) => {
			await update();
			if (result.type === 'success') {
				resetScoreForm();
				scoreSheetOpen = false;
			}
		};
	}

	function eventTargets(
		event: { round_event_players: Array<{ player_id: string }> },
		team: { game_players: Array<{ id: string }> }
	) {
		return team.game_players.some((player) =>
			event.round_event_players.some((target) => target.player_id === player.id)
		);
	}

	function bummerlTeamNames(round: (typeof data.rounds)[number]) {
		if (!round.winner_team_id) return 'nicht erfasst';
		const otherTeams = teams.filter((team) => team.id !== round.winner_team_id);
		const highestScore = Math.max(...otherTeams.map((team) => scoreFor(team.id, round)));
		return otherTeams
			.filter((team) => scoreFor(team.id, round) === highestScore)
			.map((team) => teamName(team.id))
			.join(', ');
	}

	function pointActionClass(action: PointAction, category: 'low' | 'medium' | 'high') {
		const selected = selectedAction?.title === action.title;
		const compact = action.title === String(action.points);
		const size = compact ? 'min-h-12' : action.title.length <= 12 ? 'min-h-16' : 'min-h-20';
		const style = selected
			? 'border-2 border-primary bg-primary/10 text-primary'
			: category === 'low'
				? 'border border-[#d8b9a3] bg-[#fffdf9] text-[#a8542f] transition hover:-translate-y-0.5 hover:border-primary dark:border-[#6c4e3d] dark:bg-[#49392f] dark:text-[#efbd92]'
				: category === 'medium'
					? 'border border-[#d2a98d] bg-[#fbf0e7] text-[#964725] transition hover:-translate-y-0.5 hover:border-primary dark:border-[#795441] dark:bg-[#574034] dark:text-[#f0b28a]'
					: 'border border-[#c99372] bg-[#f8e5d7] text-[#843d20] transition hover:-translate-y-0.5 hover:border-primary dark:border-[#8e5b40] dark:bg-[#654535] dark:text-[#f4b78e]';

		return `inline-flex w-fit max-w-full flex-col items-center justify-center rounded-xl px-3 py-2.5 text-center font-bold ${size} ${style}`;
	}
</script>

<svelte:head>
	<title>{gameTitle()} | bummerl</title>
</svelte:head>

<main class="mx-auto max-w-6xl px-3 py-5 sm:px-8 sm:py-14">
	<a
		href={resolve('/app')}
		class="inline-flex min-h-10 items-center gap-2 text-xs font-semibold text-muted-foreground transition hover:text-primary sm:text-sm"
	>
		<ArrowLeft size={16} /> Zurück zu meinen Spielen
	</a>

	<div class="mt-4 flex flex-col justify-between gap-3 sm:mt-7 sm:flex-row sm:items-end">
		<div class="min-w-0">
			<p class="text-xs font-bold tracking-[0.16em] text-primary uppercase sm:text-sm">
				Dein Spiel
			</p>
			<h1
				class="mt-1 truncate font-serif text-2xl font-semibold tracking-tight text-[#123d35] sm:mt-2 sm:text-5xl dark:text-[#f5f0e5]"
			>
				{gameTitle()}
			</h1>
		</div>
		{#if activeRound}
			<div
				class="rounded-full bg-[#e6eee4] px-3 py-1.5 text-xs font-bold text-[#277150] sm:px-4 sm:py-2 sm:text-sm dark:bg-[#21443b] dark:text-[#a8d8bc]"
			>
				Runde {activeRound.round_number}
			</div>
		{:else}
			<form method="POST" action="?/startRound" use:enhance>
				<Button type="submit">Runde starten</Button>
			</form>
		{/if}
	</div>

	{#if form?.message}
		<div
			class="mt-4 flex items-start gap-2 rounded-xl border border-[#b6d0bb] bg-[#eaf4eb] px-3 py-2 text-xs leading-5 text-[#2c6c43] sm:mt-6 sm:gap-3 sm:px-4 sm:py-3 sm:text-sm sm:leading-6 dark:border-[#31574b] dark:bg-[#21443b] dark:text-[#b4d3bf]"
		>
			<CheckCircle2 size={15} class="mt-0.5 shrink-0 sm:size-[18px]" />
			{form.message}
		</div>
	{/if}

	<Card class="mt-5 overflow-hidden sm:mt-10">
		<div
			class="hidden border-b border-border bg-[#f5f0e5] px-3 py-3 sm:block sm:px-8 sm:py-4 dark:bg-[#21443b]"
		>
			<p
				class="text-[0.65rem] font-bold tracking-[0.12em] text-[#6b7c70] uppercase sm:text-sm sm:tracking-[0.14em] dark:text-[#b4c4bc]"
			>
				{#if activeRound}Punktetabelle · Runde {activeRound.round_number}{:else}Punktetabelle ·
					bereit für Runde 1{/if}
			</p>
		</div>
		<div class="overflow-x-auto">
			<table class="w-full table-fixed border-collapse text-left">
				<thead>
					<tr
						class="border-b border-border text-xs font-bold tracking-[0.14em] text-muted-foreground uppercase"
					>
						{#each teams as team (team.id)}
							<th
								class="px-1 py-3 text-center text-[0.65rem] leading-tight break-words sm:px-4 sm:py-5 sm:text-xs sm:tracking-[0.14em]"
							>
								<span class="block text-[0.55rem] tracking-normal text-muted-foreground sm:text-xs"
									>Team {team.team_order}</span
								>
								<span class="mt-0.5 block"
									>{team.game_players.map((player) => player.name).join(' + ')}</span
								>
								<span
									class="mt-0.5 block min-h-3 text-[0.6rem] text-primary sm:mt-1 sm:min-h-4 sm:text-base"
									>{'• '.repeat(team.bummerl_count)}</span
								>
							</th>
						{/each}
					</tr>
				</thead>
				<tbody>
					{#if activeRound}
						{#each activeRound.round_events as event (event.id)}
							<tr class="border-b border-border/50 last:border-0">
								{#each teams as team (team.id)}
									<td
										class="px-1 py-3 text-center text-sm font-semibold {eventTargets(event, team)
											? 'text-primary'
											: 'text-muted-foreground/40'} sm:px-4 sm:py-4 sm:text-base"
									>
										{eventTargets(event, team) ? event.points : '—'}
									</td>
								{/each}
							</tr>
						{/each}
					{/if}
				</tbody>
				{#if activeRound}
					<tfoot>
						<tr class="border-t-4 border-primary bg-[#123d35] dark:bg-[#0f2521]">
							{#each teams as team (team.id)}
								<td
									class="px-1 py-4 text-center font-serif text-3xl font-semibold {scoreFor(
										team.id
									) <= 0
										? 'text-[#9de0b1]'
										: 'text-[#fffaf2]'} sm:px-4 sm:py-5 sm:text-5xl">{scoreFor(team.id)}</td
								>
							{/each}
						</tr>
					</tfoot>
				{/if}
			</table>
		</div>
		{#if !activeRound}
			<div
				class="flex items-center gap-2 border-t border-border bg-card/60 px-3 py-3 text-xs text-muted-foreground sm:gap-3 sm:px-5 sm:px-8 sm:py-5 sm:text-sm"
			>
				<CircleDot size={16} class="shrink-0 text-primary" /> Starte die erste Runde, sobald die Karten
				ausgeteilt sind.
			</div>
		{/if}
	</Card>

	{#snippet roundEntry()}
		<div>
			<div class="flex items-start justify-between gap-4">
				<div>
					<p class="text-xs font-bold tracking-[0.15em] text-primary uppercase">Punkte eintragen</p>
					<h2 class="mt-1 font-serif text-3xl font-semibold">Wie war die Runde?</h2>
					<p class="mt-2 text-sm leading-6 text-muted-foreground">
						Wähle ein Team und die Punktaktion, danach das Ergebnis.
					</p>
				</div>
				<Minus size={22} class="mt-1 text-primary" />
			</div>

			<form
				method="POST"
				action="?/applyEvent"
				use:enhance={handleScoreSubmit}
				class="mt-6 pb-20 sm:pb-0"
			>
				<input type="hidden" name="roundId" value={activeRound?.id ?? ''} />
				<input type="hidden" name="selectedTeamId" value={selectedTeamId ?? ''} />
				<input
					type="hidden"
					name="action"
					value={selectedAction ? `${selectedAction.title}|${selectedAction.points}` : ''}
				/>

				<div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
					{#each teams as team (team.id)}
						<button
							type="button"
							aria-pressed={selectedTeamId === team.id}
							class={selectedTeamId === team.id
								? 'min-h-16 rounded-xl border-2 border-primary bg-primary/10 px-3 py-3 text-left text-primary shadow-sm'
								: 'min-h-16 rounded-xl border border-border bg-background px-3 py-3 text-left text-foreground transition hover:border-primary/50'}
							onclick={() => selectTeam(team.id)}
						>
							<span class="block text-xs font-semibold text-primary">Team {team.team_order}</span>
							<span class="mt-1 block truncate text-sm font-bold"
								>{team.game_players.map((player) => player.name).join(' + ')}</span
							>
							<span class="mt-1 block text-xs font-medium text-muted-foreground"
								>{scoreFor(team.id)} Punkte</span
							>
						</button>
					{/each}
				</div>

				<div class="mt-5 space-y-4">
					{#each availablePointActionGroups as group (group.key)}
						<div>
							<div class="flex flex-wrap items-stretch gap-2">
								{#each group.actions as action (action.title)}
									<button
										type="button"
										aria-pressed={selectedAction?.title === action.title}
										class={pointActionClass(action, group.key)}
										onclick={() => (selectedAction = action)}
									>
										<span class="block text-sm leading-tight break-words whitespace-normal"
											>{action.title === String(action.points)
												? Math.abs(action.points)
												: action.title}</span
										>
										{#if action.title !== String(action.points)}
											<span class="mt-1.5 block text-xs font-semibold opacity-75"
												>{Math.abs(action.points)} Punkte</span
											>
										{/if}
									</button>
								{/each}
							</div>
						</div>
					{/each}
				</div>

				{#if selectedAction && selectedTeam}
					<div
						class="mt-5 rounded-xl border border-[#b6d0bb] bg-[#eaf4eb] px-4 py-3 text-sm leading-6 text-[#2c6c43] dark:border-[#31574b] dark:bg-[#21443b] dark:text-[#b4d3bf]"
					>
						<strong>{selectedAction.title}{spritz ? ' · Gspritzt' : ''}</strong>
						ist für {teamName(selectedTeam.id)} vorbereitet: {Math.abs(selectedPoints)} Punkte.
					</div>
				{/if}

				{#if data.game.player_count > 2}
					<label
						class="mt-5 inline-flex min-h-12 w-fit max-w-full cursor-pointer items-center gap-3 rounded-xl border border-border bg-background px-3 py-2 transition hover:border-primary/50"
					>
						<input
							name="spritz"
							type="checkbox"
							bind:checked={spritz}
							class="size-5 shrink-0 accent-[#d97745]"
						/>
						<span>
							<span class="block text-sm font-bold text-foreground">Gspritzt</span>
							<span class="block text-xs text-muted-foreground">Punktabzug wird verdoppelt</span>
						</span>
					</label>
				{/if}

				<div class="mt-5 hidden grid-cols-2 gap-2 sm:grid sm:max-w-md">
					<button
						type="submit"
						name="mode"
						value="wins"
						disabled={!selectedTeamId || !selectedAction}
						class="min-h-14 rounded-xl bg-[#2f8b59] px-4 text-sm font-bold text-white shadow-sm transition hover:bg-[#267349] disabled:pointer-events-none disabled:opacity-50 dark:bg-[#4da873] dark:text-[#10271b] dark:hover:bg-[#63bf89]"
					>
						Gewonnen
					</button>
					<button
						type="submit"
						name="mode"
						value="loses"
						disabled={!selectedTeamId || !selectedAction}
						class="min-h-14 rounded-xl bg-[#c96638] px-4 text-sm font-bold text-white shadow-sm transition hover:bg-[#b8562d] disabled:pointer-events-none disabled:opacity-50 dark:bg-[#e58b58] dark:text-[#18241f] dark:hover:bg-[#ef9b69]"
					>
						Verloren
					</button>
				</div>

				<div class="fixed right-4 bottom-4 left-4 z-[60] grid grid-cols-2 gap-2 sm:hidden">
					<button
						type="submit"
						name="mode"
						value="wins"
						disabled={!selectedTeamId || !selectedAction}
						class="min-h-14 rounded-full bg-[#2f8b59] px-3 text-sm font-bold text-white shadow-[0_12px_30px_rgb(28_91_54_/_0.3)] disabled:pointer-events-none disabled:opacity-50 dark:bg-[#4da873] dark:text-[#10271b]"
					>
						Gewonnen
					</button>
					<button
						type="submit"
						name="mode"
						value="loses"
						disabled={!selectedTeamId || !selectedAction}
						class="min-h-14 rounded-full bg-[#c96638] px-3 text-sm font-bold text-white shadow-[0_12px_30px_rgb(80_45_25_/_0.28)] disabled:pointer-events-none disabled:opacity-50 dark:bg-[#e58b58] dark:text-[#18241f]"
					>
						Verloren
					</button>
				</div>
			</form>
		</div>
	{/snippet}

	{#if activeRound}
		<div class="hidden md:block">
			<Card class="mt-6 p-5 sm:p-7">{@render roundEntry()}</Card>
		</div>

		<button
			type="button"
			class="fixed right-4 bottom-4 z-40 inline-flex min-h-14 items-center gap-2 rounded-full bg-primary px-5 text-sm font-bold text-primary-foreground shadow-[0_12px_30px_rgb(80_45_25_/_0.28)] md:hidden"
			onclick={() => (scoreSheetOpen = true)}
			aria-label="Wie war die Runde öffnen"
		>
			<Minus size={18} /> Punkte eintragen
		</button>

		{#if scoreSheetOpen}
			<div
				class="fixed inset-0 z-50 overflow-y-auto bg-background px-3 py-3 md:hidden"
				role="dialog"
				aria-modal="true"
				aria-label="Wie war die Runde"
			>
				<div class="mx-auto min-h-full max-w-xl">
					<div class="flex min-h-12 items-center justify-between px-1">
						<p class="text-xs font-bold tracking-[0.14em] text-muted-foreground uppercase">
							Runde {activeRound.round_number}
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
			</div>
		{/if}
	{/if}

	{#if hasScoreEvents}
		<form method="POST" action="?/undoLastEvent" use:enhance class="mt-5">
			<Button type="submit" variant="secondary" class="w-full sm:w-auto"
				><Undo2 size={17} /> Letzte Aktion zurücknehmen</Button
			>
		</form>
	{/if}

	{#if completedRounds.length > 0}
		<section class="mt-10">
			<div class="flex items-center gap-3">
				<Trophy size={20} class="text-primary" />
				<h2 class="font-serif text-3xl font-semibold">Bisherige Runden</h2>
			</div>
			<div class="mt-4 grid gap-3 sm:grid-cols-2">
				{#each completedRounds as round (round.id)}
					<Card class="p-5">
						<p class="text-xs font-bold tracking-[0.14em] text-primary uppercase">
							Runde {round.round_number}
						</p>
						<p class="mt-2 text-lg font-semibold">
							{teamName(round.winner_team_id)} hat gewonnen
						</p>
						<p class="mt-1 text-sm text-muted-foreground">
							Bummerl: {bummerlTeamNames(round)}
						</p>
					</Card>
				{/each}
			</div>
		</section>
	{/if}
</main>
