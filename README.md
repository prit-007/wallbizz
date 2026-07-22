# WALLBIZZ v1.0

A premium wallpaper app powered by Wallhaven. Browse, discover, download, and save wallpapers with a dark-premium, Vogue-editorial aesthetic. Built for Web PWA + Android.

```
Wallhaven API  -->  Golang Backend (cron, 2x/day)  -->  Supabase (PostgreSQL)
                                                               ^
                                                               |
                                                     Flutter Client (Web + Android)
```

1. **Backend** syncs 168 wallpapers daily from Wallhaven (7 categories × 24 each) into Supabase
2. **Flutter app** reads directly from Supabase — never touches Wallhaven directly for browsing
3. **Auth** is gated: browsing is free, heart-tap / moodboard / NSFW search triggers sign-in (Email or Google OAuth)
4. **Wishlist + Moodboards** are per-user via Supabase Row Level Security
5. **Downloads** are stored locally in Hive, browsable in the VAULT tab

## Features

| Feature | Description |
|---------|-------------|
| 7 Category Tabs | Trending, Anime, Nature, Cyberpunk, Space, Desktop, Mobile |
| Staggered Grid | Responsive 2/3/4 column masonry grid with aspect-ratio cards |
| Hybrid Search | SFW → direct to Wallhaven; NSFW/Sketchy → backend proxy (auth-gated) |
| Detail Screen | Swipe-down-to-go-back, tap-to-toggle-UI, pinch-to-zoom, double-tap zoom |
| Watermarked Share | Overlays "WALLBIZZ" branding, temp file cleanup after sharing |
| Download + VAULT | Platform-specific downloads, progress dialog, local Hive tracking |
| Wishlist | Heart icon on every card, auth-gated, swipe-to-delete |
| Moodboard | Authenticated users can create named collections |
| Gesture Hint | First-visit overlay shows swipe/tap gestures, permanently dismissable |
| Animated Splash | "WALLBIZZ" animated letter spacing, pure black native splash |
| Lazy Tab Loading | Tabs created on first visit, kept alive via Offstage (no IndexedStack) |
| Scroll-to-Top | Re-tapping active nav item scrolls tab content to top |
| Glassmorphism UI | Frosted glass nav bar, buttons, specs card, modal sheets |
| Dynamic Theming | Detail screen tints to wallpaper's primary color |
| Dark Mode | Dark-first design with system-aware toggle |
| PWA + Android | Standalone web app + native Android APK |
| Image Proxy (Web) | CORS-safe image loading via backend proxy |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Client | Flutter 3.x (Dart 3.12+) |
| Backend | Golang, Fiber, robfig/cron |
| Database | Supabase (PostgreSQL + PostgREST + Auth) |
| Images | Wallhaven API v1 |
| Hosting | Render (Docker) + Static / Netlify |

## Quick Start

```
cd backend && cp .env.example .env && go run .          # Backend on :3000
cd app && cp .env.example .env && flutter run -d chrome # Flutter web
```

- Trigger sync: `curl -X POST http://localhost:3000/api/v1/sync`
- Flutter tests: `cd app && flutter test` (162 tests)
- Backend tests: `cd backend && go test ./...` (38 tests)

## Project Layout

```
vivek_app/
├── backend/     # Go (Fiber) — sync, search proxy, image proxy, Swagger
├── app/         # Flutter — Web PWA + Android
├── sql/         # DB migrations (schema → RLS → indexes)
└── docs/        # Architecture, Frontend, Backend, Auth, Database, Deployment
```

## Docs

| Document | Covers |
|----------|--------|
| [Architecture](docs/ARCHITECTURE.md) | System diagram, data flow, design decisions |
| [App Guide](docs/APP_GUIDE.md) | Screen-by-screen walkthrough, API endpoints, startup sequence |
| [Frontend](docs/FRONTEND.md) | Widgets, animations, services, test suite |
| [Backend](docs/BACKEND.md) | Sync logic, env vars, Docker, rate limits |
| [Database](docs/DATABASE.md) | Schema, RLS, indexes, query examples |
| [Auth](docs/AUTH.md) | Auth flow, bottom sheet, PKCE, security model |
| [Deployment](docs/DEPLOYMENT.md) | Render, Flutter web build, env vars, checklist |
| [Master Plan](docs/PLAN.md) | Execution phases, file manifest, bug log |

## License

MIT
