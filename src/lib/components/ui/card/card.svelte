<script lang="ts">
	import { cn } from '$lib/utils';

	let {
		class: className = '',
		children,
		...rest
	}: {
		class?: string;
		children?: import('svelte').Snippet;
		[key: string]: unknown;
	} = $props();
</script>

<section
	{...rest}
	class={cn(
		'rounded-[1.5rem] border border-border bg-card text-card-foreground shadow-[0_18px_50px_rgb(40_57_48_/_0.08)]',
		className
	)}
>
	{@render children?.()}
</section>
