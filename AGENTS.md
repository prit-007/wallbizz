# AGENTS.md — Vivek Wallpapers

## Structure

```
vivek_app/
├── backend/            # Go (Fiber) cron sync + search/image proxy
│   ├── main.go         # Entry: Fiber + robfig/cron + routes
│   ├── config/         # Env loading (godotenv) + validation
│   ├── handlers/
│   │   ├── sync.go     # Wallhaven → Supabase upsert (category mapping source of truth)
│   │   ├── search.go   # /api/v1/search proxy (auth-optional)
│   │   ├── proxy.go    # /api/v1/proxy-image (whitelisted hosts only)
│   │   ├── routes.go   # TriggerSync + HealthCheck
│   │   └── *_test.go   # ~30 backend test functions
│   ├── models/         # Data structs
│   ├── Dockerfile      # Multi-stage distroless
│   └── .env.example    # Tracked template
├── app/                # Flutter client (Web PWA + Android)
│   ├── lib/
│   │   ├── main.dart           # Entry: dotenv.load → Hive init → Supabase.initialize
│   │   ├── config/
│   │   │   ├── backend_config.dart  # Backend URL init (only on web)
│   │   │   ├── supabase_config.dart # Reads .env
│   │   │   └── theme_config.dart
│   │   ├── services/           # supabase_service, wallpaper_actions, wallhaven_search
│   │   ├── screens/            # home, search, detail, wishlist, settings
│   │   ├── widgets/            # grid, cards, tabs, auth sheet
│   │   └── models/             # Wallpaper data class
│   ├── test/                   # 160+ test declarations (test + testWidgets)
│   ├── .env.example            # Tracked template
│   └── pubspec.yaml            # Lists .env in assets
├── sql/                # DB migrations (schema → RLS → indexes)
└── docs/               # Detailed docs
```

## Key Architecture

- Flutter never calls Wallhaven directly for sync — reads from Supabase REST via `http` package (not `supabase-flutter` for DB queries).
- Search is hybrid: SFW queries go direct Flutter → Wallhaven (`wallhaven_search`); NSFW/Sketchy queries go through backend proxy (`GET /api/v1/search`). The proxy is auth-optional — unauthenticated requests pass through as SFW; requests with a valid Supabase JWT enable NSFW/Sketchy purity filters.
- Images are proxied on web: `Image.network` on Flutter web uses XHR, so Wallhaven's CDN triggers CORS errors. `NetworkImageWidget` routes through `BackendConfig.proxyImageUrl()` → `GET /api/v1/proxy-image?url=...` on the Go backend. The backend restricts proxied hosts to `w.wallhaven.cc` and `th.wallhaven.cc` and returns responses with CORS headers.
- Download: `DownloadService.downloadImage()` uses platform-specific paths — `dart:html` Blob (web) or `http` streaming to File (mobile). Progress is reported via callback. Download path is configurable in Settings, stored as SharedPreferences key `download_path`, defaulting to `getApplicationDocumentsDirectory()/VivekWallpapers/`.
- Backend cron schedule: `0 2,14 * * *` UTC (2 AM + 2 PM daily). Manual trigger: `POST /api/v1/sync` (returns immediately, runs in goroutine).
- Backend env vars: `PORT` (default 3000), `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `WALLHAVEN_API_KEY`, `LOG_LEVEL` (default info).
- Flutter env vars (`app/.env`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BACKEND_URL` (used only on web to override `BackendConfig._baseUrl`).
- `BackendConfig._baseUrl` hardcodes the Render production URL (`https://wallbizz.onrender.com`) and is only overridden on web. Mobile/desktop do not call `BackendConfig.init()`.
- Auth: gated on heart-tap and NSFW search; browsing is anonymous. Supabase Auth (Email + Google OAuth with PKCE on Flutter web).
- Wishlist: RLS-enforced `wishlists` table; Flutter CRUDs via Supabase REST with anon key.
- DB: 2 tables — `wallpapers` (cache, UPSERT by `wallhaven_id`) and `wishlists` (user data).
- Categories: Trending, Anime, AMOLED, Desktop, Mobile — stored as `source_query` column. Category query params in `handlers/sync.go:22-28` are the source of truth.
- Swagger UI served at `/swagger/*` on the backend.

> Full workflow walkthrough with exact API calls, pagination math, auth flow, and file-line references → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Commands

| What | Command |
|------|---------|
| Run backend | `cd backend && cp .env.example .env && go run .` |
| Backend tests | `cd backend && go test ./...` |
| Trigger manual sync | `curl -X POST http://localhost:3000/api/v1/sync` |
| Run Flutter app (web) | `cd app && cp .env.example .env && flutter run -d chrome` |
| Flutter tests | `cd app && flutter test` |
| Flutter analyze | `cd app && flutter analyze` |
| Flutter build web | `cd app && flutter build web --release` |

Backend and Flutter tests are independent — run in any order or in parallel in separate terminals.

## Non-Obvious Facts

- `.env` in `app/` and `backend/` is gitignored but required at runtime. For Flutter, `.env` is listed in `pubspec.yaml` assets and loaded by `flutter_dotenv`; copy from `.env.example` before building. For Go, copy `backend/.env.example` to `backend/.env` before running.
- Backend uses `SUPABASE_SERVICE_KEY` (bypasses RLS for writes). Flutter uses `SUPABASE_ANON_KEY` (RLS-enforced reads/writes).
- Supabase upsert header: `Prefer: resolution=merge-duplicates` — driven by `wallhaven_id` UNIQUE constraint.
- Category query mapping in `backend/handlers/sync.go:22-28` is the source of truth for Wallhaven query params.
- CORS is wide open (`AllowOrigins: "*"`) on the backend — expected for Flutter web + Render.
- `pubspec.lock` is gitignored — `flutter pub get` re-resolves each time.
- `BackendConfig._baseUrl` hardcodes the production Render URL (`https://wallbizz.onrender.com`); override on web via `BACKEND_URL` in `app/.env`.

## Migrations

Run `sql/001_schema.sql` → `002_rls.sql` → `003_indexes.sql` in Supabase SQL Editor, in order.

## Deployment

- **Backend**: Render — set root dir to `backend/`, runtime Docker, add env vars (`PORT`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `WALLHAVEN_API_KEY`, `LOG_LEVEL`).
- **Flutter Web**: `flutter build web --release` then deploy `build/web/` to static host. Ensure `BACKEND_URL` in `app/.env` is set to the deployed Render URL before building.
