# AGENTS.md — Wallbizz v1.7.0

## Structure

```
wallbizz/
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
│   │   ├── main.dart           # Entry: dotenv.load → Hive init → Supabase.initialize + pure black native splash
│   │   ├── config/
│   │   │   ├── backend_config.dart  # Backend URL init (only on web)
│   │   │   ├── supabase_config.dart # Reads .env
│   │   │   └── theme_config.dart
│   │   ├── services/           # supabase_service, wallpaper_actions, wallhaven_search, download_service, downloads_service, moodboard_service
│   │   ├── screens/            # home, search, detail, wishlist, downloads, settings, splash, wallpaper_editor
│   │   ├── widgets/            # grid, cards, tabs, auth sheet, moodboard sheets, gesture_hint_overlay, network_image
│   │   └── models/             # Wallpaper, DownloadedWallpaper, Moodboard data classes
│   ├── test/                   # 160+ test declarations (test + testWidgets)
│   ├── .env.example            # Tracked template
│   └── pubspec.yaml            # Lists .env in assets
├── sql/                # DB migrations (schema → RLS → indexes)
└── docs/               # Detailed docs
```

## Key Architecture (v1.7.0)

- **Version:** v1.8.7 — Bugfix release: wishlist/moodboard 400 fix, web black screen fix.
- **Flutter never calls Wallhaven directly for sync** — reads from Supabase REST via `http` package (not `supabase-flutter` for DB queries).
- **Search is hybrid:** SFW queries go direct Flutter → Wallhaven (`wallhaven_search`); NSFW/Sketchy queries go through backend proxy (`GET /api/v1/search`). The proxy is auth-optional — unauthenticated requests pass through as SFW; requests with a valid Supabase JWT enable NSFW/Sketchy purity filters.
- **Images are proxied on web:** `Image.network` on Flutter web uses XHR, so Wallhaven's CDN triggers CORS errors. `NetworkImageWidget` routes through `BackendConfig.proxyImageUrl()` → `GET /api/v1/proxy-image?url=...` on the Go backend. The backend restricts proxied hosts to `w.wallhaven.cc` and `th.wallhaven.cc` and returns responses with CORS headers.
- **HugeIcons everywhere** — all Material `Icons.*` replaced with `HugeIcons.strokeRounded*`. `IconData` parameters changed to `dynamic`. Widget: `HugeIcon(icon: HugeIcons.strokeRoundedXxx, ...)`.
- **About Us / Manifesto screen** (`settings_about_screen.dart`) — full editorial about page with brand hero, vision, provenance ("Developer's Paradise"), and tech badges.
- **Lazy tab loading:** Replaced `IndexedStack` with lazy-initialized `Offstage` widgets — tabs are created on first visit and kept alive without paying the cost upfront.
- **Scroll-to-top on re-tap:** Tapping an already-active bottom nav item scrolls that tab's content to top.
- **Swipe-down-to-go-back on detail screen:** Dragging the image down past 25% of screen height pops the screen; otherwise snaps back.
- **Tap-to-toggle-UI on detail screen:** Single tap hides/shows the top bars and bottom action panel for immersive viewing.
- **Watermarked share:** `ShareUtils.shareWithWatermark()` fetches the image, overlays "WALLBIZZ" branding, and shares via the share sheet. Temp files are cleaned up after sharing.
- **Download:** `DownloadService.downloadImage()` uses platform-specific paths — `dart:html` Blob (web) or `http` streaming to File (mobile). Progress is reported via callback. Downloads are tracked locally in a Hive box and shown in the VAULT (Downloads) tab.
- **Moodboard:** Authenticated users can create named moodboards via `MoodboardService`. Each moodboard is stored in the `moodboards` and `moodboard_items` Supabase tables.
- **Gesture hint overlay** (`GestureHintOverlay`): First visit to detail screen shows gesture guide (swipe down, swipe left/right, tap, double-tap, heart, share) with responsive grid on desktop. Dismissed permanently via SharedPreferences.
- **Animated splash screen with pure black native splash:** `splash_screen.dart` shows "WALLBIZZ" with animated letter spacing. Native splash (Android) is configured pure black via `launch_background.xml` and `values/styles.xml`.
- **Android signing:** CI uses GitHub Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`). Local dev uses `key.properties` (gitignored, template in `key.properties.example`).
- **CI/CD:** Single `ci.yml` workflow — backend tests, Flutter analyze/test, then parallel builds for Android (signed), iOS, Windows (Inno Setup installer), Linux (tarball), macOS (zip), web. Release job downloads all platform artifacts and creates GitHub Release with CHANGELOG notes.
- **`flutter-prep` composite action** — shared setup (pub get, version extraction, .env creation) used by all CI jobs.
- **Backend cron schedule:** `0 2,14 * * *` UTC (2 AM + 2 PM daily). Manual trigger: `POST /api/v1/sync` (returns immediately, runs in goroutine).
- **Backend env vars:** `PORT` (default 3000), `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `WALLHAVEN_API_KEY`, `LOG_LEVEL` (default info).
- **Flutter env vars (`app/.env`):** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BACKEND_URL` (used only on web to override `BackendConfig._baseUrl`).
- **`BackendConfig._baseUrl`** hardcodes the Render production URL (`https://wallbizz.onrender.com`) and is only overridden on web. Mobile/desktop do not call `BackendConfig.init()`.
- **Auth:** Gated on heart-tap, moodboard access, and NSFW search; browsing is anonymous. Supabase Auth (Email + Google OAuth with PKCE on Flutter web).
- **Wishlist:** RLS-enforced `wishlists` table; Flutter CRUDs via Supabase REST with anon key.
- **DB:** 4 tables — `wallpapers` (cache, UPSERT by `wallhaven_id`), `wishlists` (user data), `moodboards` (named collections), `moodboard_items` (wallpaper references).
- **Categories:** Trending, Anime, Nature, Cyberpunk, Space, Desktop, Mobile — stored as `source_query` column. Category query params in `handlers/sync.go:22-30` are the source of truth.
- **Swagger UI** served at `/swagger/*` on the backend.

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
