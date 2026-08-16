<script lang="ts">
	import { ArrowLeft, CircleHelp, Users } from '@lucide/svelte';
	import CardShuffleLoading from '$lib/components/card-shuffle-loading.svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card } from '$lib/components/ui/card';

	let {
		onCreate,
		onCancel
	}: {
		onCreate: (input: { playerNames: string[]; startingPoints: number }) => Promise<void>;
		onCancel: () => void;
	} = $props();
	let playerCount = $state(2);
	let playerNames = $state(['', '']);
	let startingPoints = $state(7);
	let message = $state('');
	let creating = $state(false);
	const playerGroups = $derived(
		playerCount === 4
			? [
					[0, 1],
					[2, 3]
				]
			: [Array.from({ length: playerCount }, (_, index) => index)]
	);
	function setPlayerCount(count: number) {
		playerCount = count;
		playerNames = Array.from({ length: count }, (_, index) => playerNames[index] ?? '');
		startingPoints = count === 2 ? 7 : 24;
	}
	async function create() {
		const names = playerNames.map((name) => name.trim());
		if (names.some((name) => !name)) {
			message = 'Bitte gib für jeden Spieler einen Namen ein.';
			return;
		}
		creating = true;
		message = '';
		try {
			await onCreate({ playerNames: names, startingPoints });
		} catch (error) {
			message = error instanceof Error ? error.message : 'Das Spiel konnte nicht erstellt werden.';
		} finally {
			creating = false;
		}
	}
</script>

{#if creating}
	<CardShuffleLoading message="Spiel wird vorbereitet" />
{/if}

<main class="mx-auto max-w-3xl px-3 py-5 sm:px-8 sm:py-14">
	<button
		type="button"
		class="inline-flex min-h-10 items-center gap-2 text-xs font-semibold text-muted-foreground transition hover:text-primary sm:text-sm"
		onclick={onCancel}><ArrowLeft size={16} /> Zurück zu meinen Spielen</button
	>
	<Card
		class="mt-2 rounded-none border-0 bg-transparent shadow-none sm:mt-8 sm:rounded-[1.5rem] sm:border sm:border-border sm:bg-card sm:shadow-[0_18px_50px_rgb(40_57_48_/_0.08)]"
		><form
			class="px-0 py-2 sm:px-10 sm:py-9"
			onsubmit={(event) => {
				event.preventDefault();
				create();
			}}
		>
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
			{#if message}<div
					class="mt-4 rounded-xl border border-[#d99b7b] bg-[#fff0e8] px-3 py-2 text-sm text-[#9b4f30] dark:bg-[#3f3327] dark:text-[#efbd92]"
				>
					{message}
				</div>{/if}
			<fieldset class="mt-6 sm:mt-8">
				<legend class="text-sm font-bold">Anzahl der Spieler</legend>
				<div class="mt-3 grid grid-cols-3 gap-2 sm:gap-3">
					{#each [2, 3, 4] as count (count)}<button
							type="button"
							disabled={creating}
							class={count === playerCount
								? 'rounded-xl border-2 border-primary bg-primary/10 px-2 py-2.5 text-sm font-bold text-primary sm:px-4 sm:py-3'
								: 'rounded-xl border border-border bg-card px-2 py-2.5 text-sm font-semibold text-muted-foreground transition hover:border-primary/50 sm:px-4 sm:py-3'}
							onclick={() => setPlayerCount(count)}>{count} Spieler</button
						>{/each}
				</div>
			</fieldset>
			<fieldset
				class={playerCount === 4
					? 'mt-6 grid gap-3 sm:mt-8 sm:grid-cols-2 sm:gap-4'
					: 'mt-6 space-y-3 sm:mt-8 sm:space-y-4'}
			>
				<legend class="text-sm font-bold sm:col-span-2">Spielernamen</legend
				>{#each playerGroups as group, groupIndex (groupIndex)}<div
						class={playerCount === 4
							? 'rounded-2xl border border-border bg-background/60 p-3 sm:p-4'
							: 'contents'}
					>
						{#if playerCount === 4}<p
								class="mb-3 text-xs font-bold tracking-[0.14em] text-primary uppercase"
							>
								Team {groupIndex + 1}
							</p>{/if}
						<div class="space-y-3">
							{#each group as index (index)}<label class="block"
									><span
										class="mb-1.5 block text-xs font-semibold tracking-wide text-muted-foreground uppercase"
										>Spieler {index + 1}</span
									><input
										bind:value={playerNames[index]}
										required
										maxlength="80"
										placeholder={index === 0 ? 'z. B. Anna' : `Name von Spieler ${index + 1}`}
										class="min-h-11 w-full rounded-xl border border-border bg-background px-3 text-base transition outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 sm:min-h-12 sm:px-4"
									/></label
								>{/each}
						</div>
					</div>{/each}
			</fieldset>
			<fieldset class="mt-6 sm:mt-8">
				<div class="flex items-center justify-between gap-4">
					<div>
						<legend class="text-sm font-bold">Startpunkte</legend>
						<p class="mt-1 text-sm text-muted-foreground">
							Standard: {playerCount === 2 ? '7' : '24'} Punkte
						</p>
					</div>
					<CircleHelp size={18} class="text-muted-foreground" />
				</div>
				<div class="mt-3 flex items-center gap-3">
					<input
						type="number"
						bind:value={startingPoints}
						min="1"
						max="999"
						required
						class="min-h-11 w-28 rounded-xl border border-border bg-background px-3 text-center text-lg font-bold sm:min-h-12 sm:w-32"
					/><span class="text-sm text-muted-foreground">Punkte pro Runde</span>
				</div>
			</fieldset>
			<div
				class="mt-8 flex flex-col-reverse justify-between gap-3 border-t border-border pt-4 sm:mt-10 sm:flex-row sm:items-center sm:pt-6"
			>
				<button
					type="button"
					class="inline-flex min-h-11 items-center justify-center gap-2 rounded-full px-4 text-sm font-semibold text-muted-foreground hover:bg-muted"
					onclick={onCancel}><ArrowLeft size={16} /> Abbrechen</button
				><Button type="submit" loading={creating}
					>{creating ? 'Spiel wird erstellt ...' : 'Spiel erstellen'}
					{#if !creating}<Users size={17} />{/if}</Button
				>
			</div>
		</form></Card
	>
</main>
