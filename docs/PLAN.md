# Master Plan

## Goal

Build a premium wallpaper app (Flutter + Golang backend) powered exclusively by Wallhaven API, with Supabase as the database/auth layer, featuring a staggered grid, dynamic color theming, glassmorphism detail view, and wishlist with gated auth.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Golang, Fiber, robfig/cron |
| Database | Supabase (PostgreSQL + PostgREST + Auth) |
| Client | Flutter 3.x (Dart 3.12+) |
| Image Source | Wallhaven API v1 |
| Deployment | Railway (backend), Static hosting (Flutter web) |

## Execution Phases

### Phase A: SQL Schemas
Create 3 tables + RLS + indexes in Supabase SQL Editor.

**Files:** `sql/001_schema.sql`, `sql/002_rls.sql`, `sql/003_indexes.sql`

### Phase B: Golang Backend
Fiber HTTP server with cron scheduler. Fetches from Wallhaven 5 category queries, upserts to Supabase via REST API. Runs twice daily.

**Files:** `backend/main.go`, `backend/config/config.go`, `backend/handlers/sync.go`, `backend/models/wallpaper.go`, `backend/Dockerfile`, `backend/.env.example`

### Phase C: Flutter Skeleton + Home + Grid
Flutter app with Supabase init, responsive GridView, category tabs, wallpaper cards with cached thumbnails.

**Files:** `app/lib/main.dart`, `app/lib/config/supabase_config.dart`, `app/lib/models/wallpaper.dart`, `app/lib/services/supabase_service.dart`, `app/lib/screens/home_screen.dart`, `app/lib/widgets/staggered_grid.dart`, `app/lib/widgets/wallpaper_card.dart`, `app/lib/widgets/category_tabs.dart`

### Phase D: Detail Screen + Dynamic Theming
Full-screen detail view with dynamic background tinting, glassmorphism specs card, download button.

**Files:** `app/lib/screens/detail_screen.dart`, `app/lib/widgets/specs_card.dart`, `app/lib/widgets/dynamic_theme.dart`, `app/lib/utils/color_utils.dart`

### Phase E: Wishlist + Gated Auth
Heart icon on every card. Tapping as guest opens auth bottom sheet. After auth, wallpaper saved to wishlist.

**Files:** `app/lib/screens/wishlist_screen.dart`, `app/lib/widgets/auth_bottom_sheet.dart`, `app/lib/services/wallpaper_actions.dart`

### Phase F: Platform Config
Android manifest permissions. Web PWA manifest.

**Files:** `app/android/app/src/main/AndroidManifest.xml`, `app/web/manifest.json`

### Phase G: Documentation
README + 7 detailed docs.

**Files:** `README.md`, `docs/PLAN.md`, `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/BACKEND.md`, `docs/FRONTEND.md`, `docs/AUTH.md`, `docs/DEPLOYMENT.md`

### Phase H: Search Feature + Responsive Layout
Full-stack search with hybrid SFW-direct/NSFW-proxy architecture. Responsive layout improvements for search bar, category tabs, and loading skeleton.

**Files:** `backend/handlers/search.go`, `app/lib/services/wallhaven_search.dart`, `app/lib/screens/search_screen.dart`, `app/lib/screens/home_screen.dart`, `app/lib/widgets/category_tabs.dart`, `app/lib/widgets/staggered_grid.dart`

## Test Suites

| Suite | File | Tests |
|-------|------|-------|
| ColorUtils | `test/utils/color_utils_test.dart` | 10 |
| ColorUtils Edge | `test/utils/color_utils_edge_test.dart` | 16 |
| Wallpaper Model | `test/models/wallpaper_test.dart` | 12 |
| Wallpaper Model Edge | `test/models/wallpaper_extra_test.dart` | 17 |
| WallpaperCard | `test/widgets/wallpaper_card_test.dart` | 10 |
| SpecsCard | `test/widgets/specs_card_test.dart` | 10 |
| CategoryTabs | `test/widgets/category_tabs_test.dart` | 8 |
| DynamicTheme | `test/widgets/dynamic_theme_test.dart` | 6 |
| SettingsScreen | `test/screens/settings_screen_test.dart` | 12 |
| SearchScreen | `test/screens/search_screen_test.dart` | 15 |
| HomeScreen | `test/screens/home_screen_test.dart` | 7 |
| WallhavenSearch | `test/services/wallhaven_search_test.dart` | 23 |
| Go: Models | `models/wallpaper_test.go` | 4 |
| Go: Models Extra | `models/wallpaper_extra_test.go` | 7 |
| Go: Sync Handlers | `handlers/sync_test.go` | 6 |
| Go: Sync Handlers Extra | `handlers/sync_extra_test.go` | 13 |
| Go: Search Handlers | `handlers/search_test.go` | 8 |
| Go: Config | `config/config_test.go` | 6 |
| **Total** | | **174** |

**Status:** Flutter 162/162 passing, Go 38/38 passing. Zero analyzer issues.

## Bug Fixes Log

| # | Bug | File | Fix |
|---|-----|------|-----|
| 1 | `home_screen.dart` cached `_screens` list -- category changes never rebuilt grid | `home_screen.dart` | Replaced cached list with `_buildCurrentScreen()` in `build()` |
| 2 | `wallpaper_actions.dart` created dummy Wallpaper for pending auth | `wallpaper_actions.dart` | Stored full Wallpaper object instead of dummy |
| 3 | `wishlist_screen.dart` used raw NetworkImage -- no caching/clipping | `wishlist_screen.dart` | CachedNetworkImage + ClipRRect |
| 4 | `wishlist_screen.dart` Dismissible + DecorationImage didn't clip | `wishlist_screen.dart` | Added ClipRRect wrapper |
| 5 | `detail_screen.dart` used Platform.isAndroid -- crashes on web | `detail_screen.dart` | Replaced with `!kIsWeb` |
| 6 | Duplicate `_hexToColor` in detail_screen and dynamic_theme | `color_utils.dart` | Extracted to shared ColorUtils |
| 7 | Leaked auth stream subscription in wishlist_screen | `wishlist_screen.dart` | Stored subscription, cancelled in dispose() |
| 8-11 | 4 unused imports across files | Various | Removed |
| 12 | `withOpacity` deprecated (14 occurrences) | Various | Replaced with `withValues(alpha:)` |
| 13 | `activeColor` deprecated on SwitchListTile | `settings_screen.dart` | Changed to `activeThumbColor` |
| 14 | `anonKey` deprecated in Supabase.initialize | `main.dart` | Changed to `publishableKey` |
| 15 | `categories=100` (general only) for anime query | `sync.go` | Fixed to `categories=010` (anime only) per API spec |
| 16 | Missing `topRange` param for toplist sorting | `sync.go` | Added `topRange=3M` for better variety |

## Pre-Deployment Checklist

- [ ] Create Supabase project
- [ ] Enable Email/Password auth
- [ ] Enable Google OAuth auth
- [ ] Get Wallhaven API key ([wallhaven.cc/settings#api](https://wallhaven.cc/settings#api))
- [ ] Run SQL migration scripts
- [ ] Fill backend `.env` with keys
- [ ] Fill app `.env` with Supabase URL + Anon Key
- [ ] Trigger `POST /api/sync` to populate database
- [ ] Verify Flutter app loads wallpapers
- [ ] Test search: SFW queries go direct to Wallhaven (check network tab)
- [ ] Test search: NSFW/Sketchy queries go through `/api/search` proxy (requires auth)
