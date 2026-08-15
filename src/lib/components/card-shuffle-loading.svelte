<script lang="ts">
	let {
		title = 'Karten mischen',
		message = 'Bitte einen Moment'
	}: { title?: string; message?: string } = $props();
</script>

<div
	class="card-shuffle-overlay"
	role="status"
	aria-live="assertive"
	aria-label={`${message}. ${title}.`}
>
	<div class="card-shuffle" aria-hidden="true">
		<span class="shuffle-card shuffle-card-one">
			<span class="card-corner">A<br />♠</span><strong>♠</strong>
		</span>
		<span class="shuffle-card shuffle-card-two">
			<span class="card-corner">A<br />♣</span><strong>♣</strong>
		</span>
		<span class="shuffle-card shuffle-card-three card-red">
			<span class="card-corner">A<br />♥</span><strong>♥</strong>
		</span>
		<span class="shuffle-card shuffle-card-four card-red">
			<span class="card-corner">A<br />♦</span><strong>♦</strong>
		</span>
	</div>
	<p class="mt-9 font-serif text-3xl font-semibold tracking-tight text-[#fffaf2]">{title}</p>
	<p class="mt-2 text-sm font-medium text-[#d8e5dc]">{message}</p>
</div>

<style>
	.card-shuffle-overlay {
		position: fixed;
		inset: 0;
		z-index: 100;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		background:
			radial-gradient(circle at 50% 42%, rgb(83 143 111 / 0.45), transparent 17rem), #123d35;
	}

	.card-shuffle {
		position: relative;
		width: 17rem;
		height: 9rem;
	}

	.shuffle-card {
		position: absolute;
		top: 0;
		left: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		width: 7rem;
		height: 8.5rem;
		border: 2px solid #123d35;
		border-radius: 0.75rem;
		background: #fffaf2;
		box-shadow: 0 1rem 2rem rgb(5 31 25 / 0.3);
		transform-origin: 50% 110%;
		will-change: transform;
	}

	.shuffle-card strong {
		font-size: 3.5rem;
		font-weight: 500;
		color: #123d35;
	}

	.card-corner {
		position: absolute;
		top: 0.55rem;
		left: 0.65rem;
		font-family: ui-monospace, monospace;
		font-size: 0.75rem;
		font-weight: 800;
		line-height: 0.8rem;
		color: #123d35;
	}

	.card-red strong,
	.card-red .card-corner {
		color: #c34d36;
	}

	.shuffle-card-one {
		z-index: 1;
		--source-x: -4.7rem;
		--source-y: 0.35rem;
		--source-rotation: -5deg;
		--target-x: 0;
		--target-y: 0.75rem;
		--target-rotation: -1deg;
		animation-delay: 0s;
	}

	.shuffle-card-two {
		z-index: 3;
		--source-x: -4.7rem;
		--source-y: 0;
		--source-rotation: -2deg;
		--target-x: 0;
		--target-y: 0.25rem;
		--target-rotation: 1deg;
		animation-delay: 0.28s;
	}

	.shuffle-card-three {
		z-index: 2;
		--source-x: 4.7rem;
		--source-y: 0.35rem;
		--source-rotation: 5deg;
		--target-x: 0;
		--target-y: 0.5rem;
		--target-rotation: -1deg;
		animation-delay: 0.14s;
	}

	.shuffle-card-four {
		z-index: 4;
		--source-x: 4.7rem;
		--source-y: 0;
		--source-rotation: 2deg;
		--target-x: 0;
		--target-y: 0;
		--target-rotation: 1deg;
		animation-delay: 0.42s;
	}

	.shuffle-card-one,
	.shuffle-card-two,
	.shuffle-card-three,
	.shuffle-card-four {
		animation-name: riffle-shuffle;
		animation-duration: 1.6s;
		animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
		animation-direction: alternate;
		animation-iteration-count: infinite;
		animation-fill-mode: both;
	}

	@keyframes riffle-shuffle {
		0%,
		6% {
			transform: translateX(-50%) translate(var(--source-x), var(--source-y))
				rotate(var(--source-rotation));
		}
		18% {
			transform: translateX(-50%) translate(var(--source-x), -0.8rem) rotate(0deg) scale(1.04);
		}
		36% {
			transform: translateX(-50%) translate(-0.45rem, -0.55rem) rotate(4deg) scale(1.04);
		}
		48%,
		100% {
			transform: translateX(-50%) translate(var(--target-x), var(--target-y))
				rotate(var(--target-rotation));
		}
	}
</style>
