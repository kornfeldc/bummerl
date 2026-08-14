# Bummerl Agent Guide

## Project

`bummerl` is a German-language SvelteKit application for tracking Schnapsen games. The frontend uses Svelte 5 runes, TypeScript, Tailwind CSS, shadcn-svelte conventions, and pnpm. Supabase is the backend and Google is the initial OAuth provider.

## Commands

- `pnpm dev`: start the local development server
- `pnpm check`: run Svelte and TypeScript checks
- `pnpm lint`: check Prettier and ESLint
- `pnpm test`: run unit tests once
- `pnpm build`: create the Vercel production build

Run `pnpm check`, `pnpm lint`, and `pnpm test` after application changes. Run `pnpm build` when changing routing, adapters, environment handling, or deployment behavior.

## Rules

- Use pnpm; do not add npm or yarn workflows.
- Keep all user-facing copy in German unless it is a technical identifier.
- Never commit secrets. Local secrets belong in `.env.local`; deployment secrets belong in Vercel environment settings.
- Only `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY` may be used by browser code. Never expose a service-role key or Supabase Management API token to the browser.
- Keep Supabase Row Level Security enabled for every user-owned table.
- Treat score changes as immutable events and perform game state transitions atomically.
- Treat mobile as the primary interface: verify important flows at 320px, 375px, and 390px widths before desktop polish.
- Keep primary controls reachable with one hand, use at least 44px touch targets, and avoid relying on hover states.
- Preserve the paper score-table metaphor and mobile usability when changing the UI. Tables may scroll horizontally, but critical scores and actions must remain understandable without desktop width.
- Keep player names, remaining points, Bummerl marks, and point actions readable without zooming.
- Prefer small, composable Svelte components. Use Svelte 5 runes syntax in new components.
- Add or update tests for scoring rules and other deterministic domain behavior.

## Structure

- `src/routes`: public, auth, and protected pages
- `src/lib/components/ui`: shadcn-svelte-compatible UI primitives
- `src/lib/supabase`: Supabase browser/server configuration
- `supabase/migrations`: database schema and RLS migrations
- `docs/plan.md`: product and implementation plan

Read `docs/plan.md` before extending the game model or database schema.

## Mobile Verification

For UI changes, check the following at a narrow viewport before considering the work complete:

- No page-level horizontal overflow outside intentionally scrollable score tables.
- Buttons and form controls are easy to tap and do not depend on hover.
- The player score table remains legible, with names and Bummerl marks visible.
- The most common action is reachable without excessive scrolling.
- Light and dark modes retain sufficient contrast.
