<script lang="ts">
	import type { Snippet } from 'svelte';
	import { cn } from '$lib/utils';

	let {
		class: className = '',
		variant = 'primary',
		type = 'button',
		disabled = false,
		children,
		...rest
	}: {
		class?: string;
		variant?: 'primary' | 'secondary' | 'ghost';
		type?: 'button' | 'submit' | 'reset';
		disabled?: boolean;
		children?: Snippet;
		[key: string]: unknown;
	} = $props();
</script>

<button
	{type}
	{disabled}
	{...rest}
	class={cn(
		'inline-flex min-h-11 items-center justify-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold tracking-[0.01em] transition focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50',
		variant === 'primary' &&
			'bg-primary text-primary-foreground shadow-[0_8px_20px_rgb(142_68_35_/_0.18)] hover:-translate-y-0.5 hover:bg-[#c76737]',
		variant === 'secondary' &&
			'border border-border bg-card text-card-foreground shadow-sm hover:-translate-y-0.5 hover:border-primary/50',
		variant === 'ghost' && 'text-foreground hover:bg-muted',
		className
	)}
>
	{@render children?.()}
</button>
