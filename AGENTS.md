# AGENTS.md — Vivek Wallpapers

## Structure

```
vivek_app/
├── backend/            # Golang (Fiber) cron sync server + search proxy
│   ├── main.go         # Entry: Fiber + robfig/cron + routes
│   ├── config/         # Env loading + validation (config.go)
│   ├── handlers/       # sync.go (Wallhaven -> Supabase), search.go (/api/search proxy)
│   ├── models/         # Data structs
│   ├── Dockerfile      # Multi-stage distroless
│   └── *_test.go       # ~38 tests
├── app/                # Flutter client
│   ├── lib/
│   │   ├── main.dart           # Entry: Supabase init + MaterialApp
│   │   ├── config/             # SupabaseConfig (reads .env)
│   │   ├── screens/            # home, search, detail, wishlist, settings
│   │   ├── widgets/            # staggered_grid, category_tabs, auth_bottom_sheet, etc.
│   │   ├── services/           # supabase_service, wallpaper_actions, wallhaven_search
│   │   └── models/             # Wallpaper data class
│   └── test/          # ~162 widget + unit tests
├── sql/                # DB migrations (schema → RLS → indexes)
└── docs/               # Detailed docs
```

## Key Architecture

- **Flutter never calls Wallhaven directly** for sync — reads from Supabase REST via `http` package (not supabase-flutter for DB queries)
- **Search is hybrid**: SFW queries go direct Flutter → Wallhaven; NSFW/Sketchy queries go through backend proxy (JWT-gated)
- **Images are proxied** on web: `Image.network` on Flutter web uses XHR (not `<img>`), so Wallhaven's CDN triggers CORS errors. `NetworkImageWidget` routes through `BackendConfig.proxyImageUrl()` → `GET /api/v1/proxy-image?url=...` on the Go backend, which fetches the image server-side and returns it with CORS headers.
- **Download**: `DownloadService.downloadImage()` uses platform-specific paths — `dart:html` Blob (web) or `http` streaming to File (mobile). Progress is reported via callback. Download path is configurable in Settings screen, stored in SharedPreferences (`download_path` key), defaulting to `getApplicationDocumentsDirectory()/VivekWallpapers/`.
- **Backend**: syncs wallpapers twice daily + proxies NSFW search + proxies images for web
- **Search is hybrid**: SFW queries go direct Flutter → Wallhaven; NSFW/Sketchy queries go through backend proxy (JWT-gated)
- **Backend**: syncs wallpapers twice daily + proxies NSFW search requests via `/api/search`
- **Auth**: gated on heart-tap and NSFW search; browsing is anonymous. Supabase Auth (Email + Google OAuth)
- **Wishlist**: RLS-enforced `wishlists` table; Flutter CRUDs via Supabase REST with anon key
- **DB**: 2 tables — `wallpapers` (cache) and `wishlists` (user data)
- **Categories**: Trending, Anime, AMOLED, Desktop, Mobile — stored as `source_query` column

> **Full workflow walkthrough** with exact API calls, pagination math, auth flow, and file-line references → [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Commands

| What | Command |
|------|---------|
| Run backend | `cd backend && go run .` |
| Backend tests | `cd backend && go test ./...` |
| Trigger manual sync | `curl -X POST http://localhost:3000/api/sync` |
| Run Flutter app (web) | `cd app && flutter run -d chrome` |
| Flutter tests | `cd app && flutter test` |
| Flutter analyze | `cd app && flutter analyze` |
| Flutter build web | `cd app && flutter build web --release` |

All tests pass together — no special order needed.

## Non-Obvious Facts

- `.env` is committed as a _runtime asset_ for Flutter (listed in `pubspec.yaml` assets). This means the `.env` file must exist in `app/` at build time.
- Backend uses `SUPABASE_SERVICE_KEY` (bypasses RLS for writes). Flutter uses `SUPABASE_ANON_KEY` (RLS-enforced reads/writes).
- Supabase upsert header: `Prefer: resolution=merge-duplicates` — driven by `wallhaven_id` UNIQUE constraint.
- Category mapping in backend `handlers/sync.go` is the source of truth for Wallhaven query params.
- CORS is wide open (`AllowOrigins: "*"`) on the backend — expected for Flutter web + Railway.
- `pubspec.lock` is gitignored — `flutter pub get` re-resolves each time.
- `BACKEND_URL` env var in `app/.env` configures the image proxy base URL for Flutter web (default `http://localhost:3000`).

## Migrations

Run `sql/001_schema.sql` → `002_rls.sql` → `003_indexes.sql` in Supabase SQL Editor, in order.

## Deployment

- **Backend**: Railway — set root dir to `backend/`, add env vars (PORT, SUPABASE_URL, SUPABASE_SERVICE_KEY, WALLHAVEN_API_KEY)
- **Flutter Web**: `flutter build web --release` then deploy `build/web/` to static host
