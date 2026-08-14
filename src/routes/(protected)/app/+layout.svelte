<script lang="ts">
	import SiteHeader from '$lib/components/site-header.svelte';

	let { data, children } = $props();
</script>

<SiteHeader authenticated userName={data.user.user_metadata?.full_name ?? data.user.email ?? ''} />
{@render children()}
