# bummerl

Der digitale Zählblock für Schnapsen-Runden.

## Entwicklung

Voraussetzungen: Node.js 22+ und pnpm 10+.

```sh
pnpm install
cp .env.example .env.local
pnpm dev
```

Ohne Supabase-Konfiguration läuft die öffentliche Oberfläche trotzdem. Für Google-Anmeldung werden `PUBLIC_SUPABASE_URL` und `PUBLIC_SUPABASE_PUBLISHABLE_KEY` benötigt.

## Prüfungen

```sh
pnpm check
pnpm lint
pnpm test
pnpm build
```

Das Projekt nutzt den Vercel-Adapter und kann direkt als SvelteKit-Projekt in Vercel importiert werden. Alle echten Zugangsdaten gehören ausschließlich in lokale oder in Vercel konfigurierte Umgebungsvariablen.

Weitere Architektur- und Produktentscheidungen stehen in [`docs/plan.md`](docs/plan.md). Repository-Regeln für spätere Agenten stehen in [`AGENTS.md`](AGENTS.md).
