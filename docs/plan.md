# Bummerl Implementation Plan

## Product

`bummerl` is a German-language calculator for the Austrian/German card game Schnapsen. A logged-in user owns multiple games. Each game records its start time, last activity, players, rounds, score events, and Bummerl counts.

The interface should feel like a small paper score sheet on a green poker table: quick to use on a phone, legible from the table, and calm in light or dark mode.

## Mobile-First UX

Mobile is the primary use case because the app is used beside a real card table. Desktop layouts should grow from the mobile experience rather than define it. The UI should support viewport widths down to 320px, with particular verification at 320px, 375px, and 390px.

- Keep primary controls reachable with one hand and use touch targets of at least 44px.
- Keep player names, remaining points, Bummerl marks, and score actions readable without zooming.
- Use intentional horizontal scrolling only for wide paper score tables; do not allow accidental page-level overflow.
- Avoid hover-only feedback or actions.
- Keep the common score action close to the bottom of the screen when the scoring flow is implemented.
- Verify both light and dark modes on narrow screens.

## Current Milestone

- SvelteKit with Svelte 5 and TypeScript
- pnpm package management
- Tailwind CSS and shadcn-svelte-compatible components
- Vercel adapter
- Supabase SSR client foundation
- Public and protected route foundation
- Google OAuth entry point and callback
- Login/logout UI in German
- Light, dark, and system preference support
- Game setup for two to four players with default or custom starting points
- User-owned games with Row Level Security
- Round creation and mobile score-table foundation
- Immutable point events with atomic score updates
- Automatic round completion, tied-highest Bummerl assignment, and next-round creation

The next major milestone is extending the score-table history and adding game archive/restore controls.

## Routes

Public routes include `/`, `/login`, and `/auth/callback`. Protected routes live below `/app` and are enforced by a server layout. Planned protected pages are `/app`, `/app/games/new`, and `/app/games/[id]`.

## Data Model

Planned tables:

- `games`: owner, player count, starting points, start/activity timestamps, archive timestamp
- `game_teams`: explicit teams for four-player games, team order, and team Bummerl totals
- `game_players`: ordered player names and team membership
- `rounds`: round number, starting points, status, winner, completion timestamp
- `round_events`: immutable title/point adjustments
- `round_event_players`: players targeted by each adjustment
- `round_player_scores`: current score per player in a round

Every user-owned record must be protected by Supabase Row Level Security. Score mutations should use an atomic database function or server-side transaction so event history, score state, round completion, Bummerl assignment, and `last_event_at` cannot diverge.

## Game Rules

- A game has two, three, or four players.
- Two- and three-player games use one team per player.
- Four-player games use two teams of two, assigned during setup.
- Scores, point events, round winners, and Bummerl awards target teams. Team members share one remaining score.
- Starting points default to 7 for two players and 24 for three or four players.
- A custom starting count is allowed.
- The player count is immutable after setup.
- Each round starts every player at the game starting count.
- A score action selects exactly one player.
- In `Gewinnt` mode, the selected player loses the chosen points.
- In `Verliert` mode, every other player loses the chosen points.
- `Gspritzt` doubles the selected point action before it is stored.
- A round ends when the first player reaches zero or below.
- The player or players with the highest remaining score receive a Bummerl.
- A new round resets all players to the original starting count.
- The last score action can be undone, including reopening a round that was just completed and removing its Bummerl awards.

Point actions are initially maintained in TypeScript as `{ title, points }` values. Examples include `-1`, `-2`, `-3`, and `{ title: 'Bettler', points: -4 }`.

## Credentials and Deployment

Real credentials must never be checked in. Local development uses `.env.local`, which is ignored by Git. Vercel should receive the public Supabase URL/key and any server-only values through its environment variable settings.

The Supabase Management API token is provisioning-only and must never be added to a `PUBLIC_` variable. Google OAuth is configured in Google Cloud and then enabled under Supabase Authentication Providers.
