<script lang="ts">
	import { CheckCircle2, Trophy, X } from '@lucide/svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';
	import type { Game, GameEvent, GameRound } from '$lib/game/model';

	let { game, round, onClose }: { game: Game; round: GameRound; onClose: () => void } = $props();
	const teams = $derived(game.teams.slice().sort((left, right) => left.order - right.order));
	const winner = $derived(teams.find((team) => team.id === round.winnerTeamId));
	const bummerlTeams = $derived.by(() => {
		if (!round.winnerTeamId) return [];
		const remainingTeams = teams.filter((team) => team.id !== round.winnerTeamId);
		const highestScore = Math.max(...remainingTeams.map((team) => round.scores[team.id]));
		return remainingTeams.filter((team) => round.scores[team.id] === highestScore);
	});
	const confettiPieces = Array.from({ length: 18 }, (_, index) => index);
	function targetNames(targetTeamIds: string[]) {
		return teams
			.filter((team) => targetTeamIds.includes(team.id))
			.map((team) => team.name)
			.join(', ');
	}
	function actionResult(event: GameEvent) {
		const actor = teams.find((team) => team.id === event.selectedTeamId);
		if (!actor || !event.mode) return `Punkte bei ${targetNames(event.targetTeamIds)}`;
		return `${actor.name} hat ${event.mode === 'wins' ? 'gewonnen' : 'verloren'}`;
	}
</script>

<div
	class="round-overview fixed inset-0 z-[70] overflow-hidden bg-[#123d35]/75 px-3 py-3 backdrop-blur-sm sm:px-6 sm:py-8"
	role="dialog"
	aria-modal="true"
	aria-labelledby="round-overview-title"
>
	<div class="mx-auto flex h-full min-h-0 max-w-2xl items-start sm:items-center">
		<Card
			class="relative flex max-h-full w-full flex-col overflow-hidden border-[#d4c8b3] bg-[#fffdf7] shadow-[0_28px_70px_rgb(10_35_28_/_0.35)] dark:border-[#31574b] dark:bg-[#17332d]"
		>
			<button
				type="button"
				class="absolute top-3 right-3 z-20 inline-flex size-11 items-center justify-center rounded-full text-[#fffaf2]/70 transition hover:bg-white/10 hover:text-white"
				onclick={onClose}
				aria-label="Rundenübersicht schließen"><X size={21} /></button
			>
			<div class="winner-header shrink-0 bg-[#123d35] px-5 py-7 text-[#fffaf2] sm:px-9 sm:py-10">
				<div class="winner-confetti" aria-hidden="true">
					{#each confettiPieces as piece (piece)}
						<span
							style={`--confetti-index: ${piece}; --confetti-x: ${(Math.cos((piece / confettiPieces.length) * Math.PI * 2) * (88 + (piece % 4) * 24)).toFixed(1)}px; --confetti-y: ${(Math.sin((piece / confettiPieces.length) * Math.PI * 2) * (62 + (piece % 3) * 24)).toFixed(1)}px`}
						></span>
					{/each}
				</div>
				<div class="relative z-10 flex items-center gap-3 text-[#f2b089]">
					<p class="text-xs font-bold tracking-[0.16em] uppercase">Runde {round.number} beendet</p>
				</div>
				<div class="winner-title relative z-10 mt-4 flex items-center gap-4 sm:gap-5">
					<span class="winner-trophy"><Trophy size={48} strokeWidth={1.5} /></span>
					<div class="min-w-0">
						<h1
							id="round-overview-title"
							class="winner-name font-serif text-4xl font-semibold tracking-tight sm:text-5xl"
						>
							{winner?.name ?? 'Die Runde ist entschieden'}
						</h1>
						<p class="winner-subtitle mt-2 text-base text-[#fffaf2]/75 sm:text-lg">
							hat diese Runde gewonnen.
						</p>
					</div>
				</div>
			</div>

			<div class="flex min-h-0 flex-1 flex-col p-5 sm:p-9">
				<section aria-labelledby="bummerl-title">
					<div
						class="flex items-start gap-3 rounded-2xl border border-[#d7a282] bg-[#fff0e8] p-4 dark:border-[#795441] dark:bg-[#3f3327]"
					>
						<CheckCircle2 size={21} class="mt-0.5 shrink-0 text-[#a8542f] dark:text-[#efbd92]" />
						<div>
							<h2 id="bummerl-title" class="font-semibold text-[#7e3f25] dark:text-[#efbd92]">
								Bummerl
							</h2>
							<p class="mt-1 text-sm leading-6 text-[#8f563a] dark:text-[#e4b090]">
								{bummerlTeams.length
									? `${bummerlTeams.map((team) => team.name).join(', ')} ${bummerlTeams.length === 1 ? 'bekommt das Bummerl.' : 'bekommen die Bummerl.'}`
									: 'Kein Bummerl wurde vergeben.'}
							</p>
						</div>
					</div>
				</section>

				<section class="mt-7" aria-labelledby="final-score-title">
					<h2
						id="final-score-title"
						class="text-xs font-bold tracking-[0.15em] text-muted-foreground uppercase"
					>
						Endstand
					</h2>
					<div
						class="mt-3 grid gap-2 {teams.length === 2
							? 'grid-cols-2'
							: teams.length === 3
								? 'grid-cols-3'
								: 'grid-cols-2 sm:grid-cols-2'}"
					>
						{#each teams as team (team.id)}
							<div
								class={team.id === round.winnerTeamId
									? 'rounded-xl bg-[#e6eee4] px-3 py-3 text-center dark:bg-[#21443b]'
									: 'rounded-xl bg-muted/60 px-3 py-3 text-center'}
							>
								<p class="truncate text-xs font-bold text-muted-foreground">{team.name}</p>
								<p
									class={team.id === round.winnerTeamId
										? 'mt-1 font-serif text-3xl font-semibold text-[#277150] dark:text-[#a8d8bc]'
										: 'mt-1 font-serif text-3xl font-semibold'}
								>
									{round.scores[team.id]}
								</p>
							</div>
						{/each}
					</div>
				</section>

				<section class="mt-7 flex min-h-0 flex-1 flex-col" aria-labelledby="events-title">
					<h2
						id="events-title"
						class="text-xs font-bold tracking-[0.15em] text-muted-foreground uppercase"
					>
						Gespielte Aktionen
					</h2>
					<div
						class="mt-3 min-h-0 flex-1 divide-y divide-border overflow-y-auto rounded-xl border border-border bg-background/50"
					>
						{#each round.events as event, index (event.id)}
							<div class="flex items-center gap-3 px-3 py-3 sm:px-4">
								<span
									class="flex size-7 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-bold text-muted-foreground"
									>{index + 1}</span
								>
								<div class="min-w-0 flex-1">
									<p
										class={event.mode === 'wins'
											? 'truncate text-sm font-semibold text-[#277150] dark:text-[#a8d8bc]'
											: event.mode === 'loses'
												? 'truncate text-sm font-semibold text-[#a8542f] dark:text-[#efbd92]'
												: 'truncate text-sm font-semibold'}
									>
										{actionResult(event)}
									</p>
									<p class="mt-0.5 truncate text-xs text-muted-foreground">
										{event.title} · {Math.abs(event.points)} Punkte
									</p>
								</div>
								<span class="font-serif text-xl font-semibold text-primary">{event.points}</span>
							</div>
						{/each}
					</div>
				</section>

				<Button class="mt-5 w-full shrink-0" onclick={onClose}>Weiter zum Spiel</Button>
			</div>
		</Card>
	</div>
</div>

<style>
	.round-overview {
		padding-top: max(1.5rem, calc(env(safe-area-inset-top) + 1rem));
		padding-bottom: max(0.75rem, env(safe-area-inset-bottom));
	}

	.winner-header {
		isolation: isolate;
		position: relative;
		overflow: hidden;
	}

	.winner-header::after {
		position: absolute;
		inset: -7rem 20% auto;
		height: 14rem;
		border-radius: 999px;
		background: rgb(242 176 137 / 0.18);
		content: '';
		filter: blur(2rem);
		animation: winner-glow 1.8s ease-out both;
	}

	.winner-trophy {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 4.5rem;
		height: 4.5rem;
		border: 1px solid rgb(242 176 137 / 0.55);
		border-radius: 1.25rem;
		background: rgb(242 176 137 / 0.16);
		box-shadow: 0 0 2rem rgb(242 176 137 / 0.22);
	}

	.winner-name {
		animation: winner-name 560ms 140ms ease-out both;
	}

	.winner-subtitle {
		animation: winner-name 560ms 240ms ease-out both;
	}

	.winner-confetti {
		pointer-events: none;
		position: absolute;
		inset: 0;
		z-index: 1;
		overflow: hidden;
	}

	.winner-confetti span {
		position: absolute;
		top: 50%;
		left: 50%;
		width: 0.5rem;
		height: 0.9rem;
		border-radius: 0.15rem;
		background: hsl(calc(22 + (var(--confetti-index) * 17)), 76%, 69%);
		opacity: 0;
		animation: confetti-explode 900ms cubic-bezier(0.15, 0.7, 0.2, 1) both;
	}

	@keyframes winner-glow {
		0% {
			opacity: 0;
			transform: scale(0.55);
		}
		55% {
			opacity: 1;
			transform: scale(1.1);
		}
		100% {
			opacity: 0.55;
			transform: scale(1);
		}
	}

	@keyframes winner-name {
		from {
			opacity: 0;
			transform: translateY(0.7rem);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	@keyframes confetti-explode {
		from {
			opacity: 0;
			transform: translate(-50%, -50%) scale(0.2) rotate(0deg);
		}
		15% {
			opacity: 1;
		}
		100% {
			opacity: 0;
			transform: translate(calc(-50% + var(--confetti-x)), calc(-50% + var(--confetti-y)))
				scale(0.9) rotate(calc(var(--confetti-index) * 85deg));
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.winner-header::after,
		.winner-name,
		.winner-subtitle {
			animation: none;
		}
	}
</style>
