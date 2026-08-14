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

	function setPlayerCount(nextCount: number) {
		playerCount = nextCount;
		playerNames = Array.from({ length: nextCount }, (_, index) => playerNames[index] ?? '');
		startingPoints = nextCount === 2 ? 7 : 24;
	}
</script>

<svelte:head>
	<title>Neues Spiel | bummerl</title>
</svelte:head>

<main class="mx-auto max-w-3xl px-5 py-10 sm:px-8 sm:py-14">
	<a
		href={resolve('/app')}
		class="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground transition hover:text-primary"
	>
		<ArrowLeft size={16} /> Zurück zu meinen Spielen
	</a>

	<Card class="mt-8">
		<form method="POST" use:enhance class="px-6 py-7 sm:px-10 sm:py-9">
			<div class="flex items-start gap-4 border-b border-border pb-7">
				<div
					class="flex size-12 shrink-0 items-center justify-center rounded-2xl bg-[#e8eee5] text-[#347258] dark:bg-[#21443b] dark:text-[#b4d3bf]"
				>
					<Users size={23} />
				</div>
				<div>
					<p class="text-sm font-bold tracking-[0.16em] text-primary uppercase">Spiel einrichten</p>
					<h1 class="mt-1 font-serif text-3xl font-semibold tracking-tight sm:text-4xl">
						Wer sitzt am Tisch?
					</h1>
					<p class="mt-2 leading-6 text-muted-foreground">
						Die Spieleranzahl bleibt nach dem Erstellen unverändert.
					</p>
				</div>
			</div>

			{#if form?.message}
				<div
					class="mt-6 rounded-xl border border-[#d99b7b] bg-[#fff0e8] px-4 py-3 text-sm leading-6 text-[#9b4f30] dark:bg-[#3f3327] dark:text-[#efbd92]"
				>
					{form.message}
				</div>
			{/if}

			<fieldset class="mt-8">
				<legend class="text-sm font-bold text-foreground">Anzahl der Spieler</legend>
				<div class="mt-3 grid grid-cols-3 gap-3">
					{#each [2, 3, 4] as count (count)}
						<button
							type="button"
							class={count === playerCount
								? 'rounded-xl border-2 border-primary bg-primary/10 px-4 py-3 text-sm font-bold text-primary'
								: 'rounded-xl border border-border bg-card px-4 py-3 text-sm font-semibold text-muted-foreground transition hover:border-primary/50 hover:text-foreground'}
							onclick={() => setPlayerCount(count)}
						>
							{count} Spieler
						</button>
					{/each}
				</div>
				<input type="hidden" name="playerCount" value={playerCount} />
			</fieldset>

			<fieldset class="mt-8 space-y-4">
				<legend class="text-sm font-bold text-foreground">Spielernamen</legend>
				{#each playerNames as name, index (index)}
					<label class="block">
						<span
							class="mb-1.5 block text-xs font-semibold tracking-wide text-muted-foreground uppercase"
							>Spieler {index + 1}</span
						>
						<input
							name="playerName"
							bind:value={playerNames[index]}
							aria-label={name ? `Name von ${name}` : `Name von Spieler ${index + 1}`}
							required
							maxlength="80"
							placeholder={index === 0 ? 'z. B. Anna' : `Name von Spieler ${index + 1}`}
							class="min-h-12 w-full rounded-xl border border-border bg-background px-4 text-base text-foreground transition outline-none placeholder:text-muted-foreground/60 focus:border-primary focus:ring-2 focus:ring-primary/20"
						/>
					</label>
				{/each}
			</fieldset>

			<fieldset class="mt-8">
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
				<div class="mt-3 flex items-center gap-3">
					<input
						name="startingPoints"
						type="number"
						bind:value={startingPoints}
						min="1"
						max="999"
						required
						class="min-h-12 w-32 rounded-xl border border-border bg-background px-4 text-center text-lg font-bold text-foreground transition outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
					/>
					<span class="text-sm text-muted-foreground">Punkte pro Runde</span>
				</div>
			</fieldset>

			<div
				class="mt-10 flex flex-col-reverse justify-between gap-3 border-t border-border pt-6 sm:flex-row sm:items-center"
			>
				<a
					href={resolve('/app')}
					class="inline-flex min-h-11 items-center justify-center gap-2 rounded-full px-4 text-sm font-semibold text-muted-foreground transition hover:bg-muted hover:text-foreground"
					><ArrowLeft size={16} /> Abbrechen</a
				>
				<Button type="submit">Spiel erstellen <Users size={17} /></Button>
			</div>
		</form>
	</Card>
</main>
