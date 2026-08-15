<script lang="ts">
	import { ArrowRight, Check, CircleDot, Layers3, ShieldCheck } from '@lucide/svelte';
	import { resolve } from '$app/paths';
	import SiteHeader from '$lib/components/site-header.svelte';
	import { Button } from '$lib/components/ui/button';

	let { data } = $props();
</script>

<svelte:head>
	<title>bummerl | Schnapsen zählen</title>
	<meta name="description" content="Der digitale Zählblock für eure Schnapsen-Runden." />
</svelte:head>

<SiteHeader
	authenticated={Boolean(data.user)}
	userName={data.user?.user_metadata?.full_name ?? data.user?.email ?? ''}
/>

<main class="overflow-hidden">
	<section
		class="relative mx-auto grid max-w-6xl items-center gap-14 px-5 py-16 sm:px-8 sm:py-24 lg:grid-cols-[1fr_0.9fr] lg:gap-20 lg:py-28"
	>
		<div class="relative z-10 max-w-2xl">
			<div
				class="mb-7 inline-flex items-center gap-2 rounded-full border border-[#c6b99f] bg-card/70 px-3.5 py-2 text-xs font-bold tracking-[0.13em] text-[#bd6138] uppercase dark:border-[#31574b] dark:text-[#e58b58]"
			>
				<CircleDot size={15} strokeWidth={2.5} />
				Für die nächste Runde
			</div>
			<h1
				class="max-w-xl font-serif text-6xl leading-[0.94] font-semibold tracking-[-0.055em] text-[#123d35] sm:text-8xl dark:text-[#f5f0e5]"
			>
				Weniger rechnen.<br /><span class="text-[#d97745] italic">Mehr spielen.</span>
			</h1>
			<p class="mt-8 max-w-lg text-lg leading-8 text-muted-foreground sm:text-xl">
				Bummerl ist euer digitaler Zählblock für Schnapsen. Schnell eingerichtet, angenehm
				übersichtlich und immer dabei, wenn der nächste Stich ausgespielt wird.
			</p>
			<div class="mt-9 flex flex-wrap items-center gap-4">
				{#if data.user}
					<a href={resolve('/app')}><Button>Zu meinen Spielen <ArrowRight size={17} /></Button></a>
				{:else}
					<a href={resolve('/auth/google')}
						><Button>Mit Google anmelden <ArrowRight size={17} /></Button></a
					>
				{/if}
				<a href={resolve('/offline')}
					><Button variant="ghost" class="min-h-9 px-3 py-1.5 text-xs"
						>Ohne Anmeldung spielen</Button
					></a
				>
			</div>
		</div>

		<div class="relative mx-auto w-full max-w-md lg:mr-2">
			<div class="absolute -inset-8 rounded-full bg-[#d97745]/10 blur-3xl"></div>
			<div
				class="relative rotate-2 rounded-[1.8rem] border border-[#d4c8b3] bg-[#fffdf7] p-5 shadow-[0_28px_70px_rgb(48_70_56_/_0.18)] dark:border-[#31574b] dark:bg-[#17332d]"
			>
				<div
					class="flex items-start justify-between border-b border-[#ddd4c5] pb-5 dark:border-[#31574b]"
				>
					<div>
						<p class="font-serif text-2xl font-semibold text-[#17332d] dark:text-[#f5f0e5]">
							Samstag, 20:15
						</p>
						<p class="mt-1 text-xs font-bold tracking-[0.15em] text-[#7b877d] uppercase">
							Gartenrunde
						</p>
					</div>
					<div
						class="rounded-full bg-[#e6eee4] px-3 py-1.5 text-xs font-bold text-[#277150] dark:bg-[#21443b] dark:text-[#a8d8bc]"
					>
						Runde 04
					</div>
				</div>
				<div class="grid grid-cols-3 gap-3 py-5 text-center">
					{#each [{ name: 'Anna', points: 8, dots: 1 }, { name: 'Sepp', points: 0, dots: 2 }, { name: 'Michi', points: 13, dots: 0 }] as player (player.name)}
						<div>
							<div class="mb-3 flex justify-center gap-1">
								{#if player.dots > 0}
									<span class="text-xs font-bold tracking-[0.2em] text-[#d97745]"
										>{'• '.repeat(player.dots)}</span
									>
								{/if}
							</div>
							<p
								class="truncate text-xs font-bold tracking-wide text-[#67746b] uppercase dark:text-[#b4c4bc]"
							>
								{player.name}
							</p>
							<p class="mt-2 font-serif text-4xl font-semibold text-[#17332d] dark:text-[#f5f0e5]">
								{player.points}
							</p>
						</div>
					{/each}
				</div>
				<div class="space-y-2 border-t border-[#ddd4c5] pt-4 text-sm dark:border-[#31574b]">
					<div
						class="grid grid-cols-3 gap-3 text-center font-medium text-[#69766c] dark:text-[#b4c4bc]"
					>
						<span>-2</span><span>-1</span><span>Bettler</span>
					</div>
					<div class="grid grid-cols-3 gap-3 text-center font-semibold text-[#bd6138]">
						<span>Anna, Michi</span><span>Sepp</span><span>Michi</span>
					</div>
				</div>
				<div
					class="mt-5 flex items-center gap-2 rounded-xl bg-[#f4eadc] px-3 py-2.5 text-xs font-semibold text-[#8f563a] dark:bg-[#3f3327] dark:text-[#efbd92]"
				>
					<Check size={15} /> Sepp gewinnt die Runde
				</div>
			</div>
		</div>
	</section>

	<section class="border-y border-border/70 bg-card/35">
		<div class="mx-auto grid max-w-6xl gap-5 px-5 py-10 sm:grid-cols-3 sm:px-8">
			<div class="flex gap-4">
				<Layers3 class="mt-1 shrink-0 text-primary" size={22} />
				<div>
					<h2 class="font-semibold">Mehrere Spiele</h2>
					<p class="mt-1 text-sm leading-6 text-muted-foreground">
						Jede Runde bleibt an ihrem Platz und kann später fortgesetzt werden.
					</p>
				</div>
			</div>
			<div class="flex gap-4">
				<CircleDot class="mt-1 shrink-0 text-primary" size={22} />
				<div>
					<h2 class="font-semibold">Bummerl im Blick</h2>
					<p class="mt-1 text-sm leading-6 text-muted-foreground">
						Punkte und verlorene Runden sind sofort sichtbar.
					</p>
				</div>
			</div>
			<div class="flex gap-4">
				<ShieldCheck class="mt-1 shrink-0 text-primary" size={22} />
				<div>
					<h2 class="font-semibold">Sicher gespeichert</h2>
					<p class="mt-1 text-sm leading-6 text-muted-foreground">
						Deine Spiele werden automatisch in deinem Konto gespeichert.
					</p>
				</div>
			</div>
		</div>
	</section>
</main>
