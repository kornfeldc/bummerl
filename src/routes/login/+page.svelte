<script lang="ts">
	import { ArrowLeft, Globe2, LockKeyhole } from '@lucide/svelte';
	import { enhance } from '$app/forms';
	import { resolve } from '$app/paths';
	import SiteHeader from '$lib/components/site-header.svelte';
	import { Card } from '$lib/components/ui/card';

	let { form } = $props();
</script>

<svelte:head>
	<title>Anmelden | bummerl</title>
	<meta
		name="description"
		content="Melde dich bei bummerl an und behalte deine Schnapsen-Spiele im Blick."
	/>
</svelte:head>

<SiteHeader />

<main
	class="mx-auto flex min-h-[calc(100vh-81px)] max-w-6xl items-center justify-center px-5 py-16 sm:px-8"
>
	<Card class="w-full max-w-md overflow-hidden">
		<div class="bg-[#e8eee5] px-7 py-8 sm:px-10 dark:bg-[#21443b]">
			<a
				href={resolve('/')}
				class="inline-flex items-center gap-1.5 text-sm font-medium text-[#43725d] transition hover:text-primary dark:text-[#b4d3bf]"
				><ArrowLeft size={15} /> Zur Startseite</a
			>
			<div
				class="mt-10 flex size-14 items-center justify-center rounded-2xl bg-[#123d35] text-[#f5f0e5] shadow-lg dark:bg-[#0f2521]"
			>
				<LockKeyhole size={24} />
			</div>
			<h1
				class="mt-6 font-serif text-4xl font-semibold tracking-tight text-[#17332d] dark:text-[#f5f0e5]"
			>
				Willkommen zurück.
			</h1>
			<p class="mt-3 max-w-xs leading-7 text-[#5a7064] dark:text-[#b4c4bc]">
				Melde dich an, damit deine Spiele immer dort weitermachen, wo du aufgehört hast.
			</p>
		</div>
		<div class="px-7 py-8 sm:px-10">
			{#if form?.message}
				<div
					class="mb-5 rounded-xl border border-[#d99b7b] bg-[#fff0e8] px-4 py-3 text-sm leading-6 text-[#9b4f30] dark:bg-[#3f3327] dark:text-[#efbd92]"
				>
					{form.message}
				</div>
			{/if}
			<form method="POST" use:enhance>
				<button
					type="submit"
					class="flex min-h-12 w-full items-center justify-center gap-3 rounded-xl border border-border bg-card px-4 text-sm font-semibold text-foreground shadow-sm transition hover:-translate-y-0.5 hover:border-primary/50 hover:shadow-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
				>
					<Globe2 size={19} class="text-[#4285f4]" />
					Mit Google anmelden
				</button>
			</form>
			<p class="mt-6 text-center text-xs leading-5 text-muted-foreground">
				Mit der Anmeldung stimmst du zu, dass bummerl dein Konto zur Speicherung deiner Spiele
				verwendet.
			</p>
		</div>
	</Card>
</main>
