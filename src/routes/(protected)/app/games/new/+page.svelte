<script lang="ts">
	import { ArrowLeft, CircleHelp, Users } from '@lucide/svelte';
	import { enhance } from '$app/forms';
	import { resolve } from '$app/paths';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';

	let { form } = $props();
	let playerCount = $state(2);
	let playerNames = $state(['', '']);
	let startingPoints = $state(7);
	let isCreating = $state(false);
	const playerGroups = $derived(
		playerCount === 4
			? [
					[0, 1],
					[2, 3]
				]
			: [Array.from({ length: playerCount }, (_, index) => index)]
	);

	function setPlayerCount(nextCount: number) {
		playerCount = nextCount;
		playerNames = Array.from({ length: nextCount }, (_, index) => playerNames[index] ?? '');
		startingPoints = nextCount === 2 ? 7 : 24;
	}

	function handleCreate() {
		isCreating = true;
		return async ({ update }: { update: () => Promise<void> }) => {
			try {
				await update();
			} finally {
				isCreating = false;
			}
		};
	}
</script>

<svelte:head>
	<title>Neues Spiel | bummerl</title>
</svelte:head>

<main class="mx-auto max-w-3xl px-3 py-5 sm:px-8 sm:py-14">
	<a
		href={resolve('/app')}
		class="inline-flex min-h-10 items-center gap-2 text-xs font-semibold text-muted-foreground transition hover:text-primary sm:text-sm"
	>
		<ArrowLeft size={16} /> Zurück zu meinen Spielen
	</a>

	<Card
		class="mt-2 rounded-none border-0 bg-transparent shadow-none sm:mt-8 sm:rounded-[1.5rem] sm:border sm:border-border sm:bg-card sm:shadow-[0_18px_50px_rgb(40_57_48_/_0.08)]"
	>
		<form method="POST" use:enhance={handleCreate} class="px-0 py-2 sm:px-10 sm:py-9">
			<div class="border-b border-border pb-4 sm:pb-7">
				<div class="flex items-start gap-4">
					<div
						class="hidden size-12 shrink-0 items-center justify-center rounded-2xl bg-[#e8eee5] text-[#347258] sm:flex dark:bg-[#21443b] dark:text-[#b4d3bf]"
					>
						<Users size={23} />
					</div>
					<div>
						<p class="text-xs font-bold tracking-[0.16em] text-primary uppercase sm:text-sm">
							Spiel einrichten
						</p>
						<h1 class="mt-1 font-serif text-2xl font-semibold tracking-tight sm:text-4xl">
							Wer sitzt am Tisch?
						</h1>
						<p
							class="mt-1 text-sm leading-5 text-muted-foreground sm:mt-2 sm:text-base sm:leading-6"
						>
							Die Spieleranzahl bleibt nach dem Erstellen unverändert.
						</p>
					</div>
				</div>
			</div>

			{#if form?.message}
				<div
					class="mt-4 rounded-xl border border-[#d99b7b] bg-[#fff0e8] px-3 py-2 text-xs leading-5 text-[#9b4f30] sm:mt-6 sm:px-4 sm:py-3 sm:text-sm sm:leading-6 dark:bg-[#3f3327] dark:text-[#efbd92]"
				>
					{form.message}
				</div>
			{/if}

			<fieldset class="mt-6 sm:mt-8">
				<legend class="text-sm font-bold text-foreground">Anzahl der Spieler</legend>
				<div class="mt-2 grid grid-cols-3 gap-2 sm:mt-3 sm:gap-3">
					{#each [2, 3, 4] as count (count)}
						<button
							type="button"
							disabled={isCreating}
							class={count === playerCount
								? 'rounded-xl border-2 border-primary bg-primary/10 px-2 py-2.5 text-sm font-bold text-primary sm:px-4 sm:py-3'
								: 'rounded-xl border border-border bg-card px-2 py-2.5 text-sm font-semibold text-muted-foreground transition hover:border-primary/50 hover:text-foreground sm:px-4 sm:py-3'}
							onclick={() => setPlayerCount(count)}
						>
							{count} Spieler
						</button>
					{/each}
				</div>
				<input type="hidden" name="playerCount" value={playerCount} />
			</fieldset>

			<fieldset
				class={playerCount === 4
					? 'mt-6 grid gap-3 sm:mt-8 sm:grid-cols-2 sm:gap-4'
					: 'mt-6 space-y-3 sm:mt-8 sm:space-y-4'}
			>
				<legend class="text-sm font-bold text-foreground sm:col-span-2">Spielernamen</legend>
				{#each playerGroups as group, groupIndex (groupIndex)}
					<div
						class={playerCount === 4
							? 'rounded-2xl border border-border bg-background/60 p-3 sm:p-4'
							: 'contents'}
					>
						{#if playerCount === 4}
							<p class="mb-3 text-xs font-bold tracking-[0.14em] text-primary uppercase">
								Team {groupIndex + 1}
							</p>
						{/if}
						<div class="space-y-3">
							{#each group as index (index)}
								<label class="block">
									<span
										class="mb-1.5 block text-xs font-semibold tracking-wide text-muted-foreground uppercase"
										>Spieler {index + 1}</span
									>
									<input
										name="playerName"
										bind:value={playerNames[index]}
										aria-label={playerNames[index]
											? `Name von ${playerNames[index]}`
											: `Name von Spieler ${index + 1}`}
										required
										maxlength="80"
										placeholder={index === 0 ? 'z. B. Anna' : `Name von Spieler ${index + 1}`}
										class="min-h-11 w-full rounded-xl border border-border bg-background px-3 text-base text-foreground transition outline-none placeholder:text-muted-foreground/60 focus:border-primary focus:ring-2 focus:ring-primary/20 sm:min-h-12 sm:px-4"
									/>
								</label>
							{/each}
						</div>
					</div>
				{/each}
			</fieldset>

			<fieldset class="mt-6 sm:mt-8">
				<div class="flex items-center justify-between gap-4">
					<div>
						<legend class="text-sm font-bold text-foreground">Startpunkte</legend>
						<p class="mt-1 text-sm text-muted-foreground">
							Standard: {playerCount === 2 ? '7' : '24'} Punkte
						</p>
					</div>
					<CircleHelp
						size={18}
						class="text-muted-foreground"
						aria-label="Die Startpunkte können angepasst werden."
					/>
				</div>
				<div class="mt-2 flex items-center gap-3 sm:mt-3">
					<input
						name="startingPoints"
						type="number"
						bind:value={startingPoints}
						min="1"
						max="999"
						required
						class="min-h-11 w-28 rounded-xl border border-border bg-background px-3 text-center text-lg font-bold text-foreground transition outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 sm:min-h-12 sm:w-32 sm:px-4"
					/>
					<span class="text-sm text-muted-foreground">Punkte pro Runde</span>
				</div>
			</fieldset>

			<div
				class="mt-8 flex flex-col-reverse justify-between gap-3 border-t border-border pt-4 sm:mt-10 sm:flex-row sm:items-center sm:pt-6"
			>
				<a
					href={resolve('/app')}
					class="inline-flex min-h-11 items-center justify-center gap-2 rounded-full px-4 text-sm font-semibold text-muted-foreground transition hover:bg-muted hover:text-foreground"
					><ArrowLeft size={16} /> Abbrechen</a
				>
				<Button type="submit" loading={isCreating}
					>{isCreating ? 'Spiel wird erstellt ...' : 'Spiel erstellen'}
					{#if !isCreating}<Users size={17} />{/if}</Button
				>
			</div>
		</form>
	</Card>
</main>
