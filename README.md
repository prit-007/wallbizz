# Vivek Wallpapers

A premium wallpaper app powered by Wallhaven. Browse, discover, and save wallpapers with a youth-centric, Vogue-editorial aesthetic.

## Goal

Build a **production-ready wallpaper app** where users can browse curated wallpapers from Wallhaven in a beautiful staggered grid, view full-screen details with dynamic color theming, and save favorites to a personal collection -- all without requiring an account until they choose to save.

## How It Works

```
Wallhaven API  -->  Golang Backend (cron, 2x/day)  -->  Supabase (PostgreSQL)
                                                               ^
                                                               |
                                                     Flutter Client (Web + Android)
```

1. **Backend** syncs 120 wallpapers daily from Wallhaven (5 categories x 24 each) into Supabase
2. **Flutter app** reads directly from Supabase -- never touches Wallhaven directly
3. **Auth** is gated: browsing is free, heart-tap triggers sign-in (email or Google OAuth)
4. **Wishlist** is per-user via Supabase Row Level Security

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Client | Flutter 3.x (Dart 3.12+) | Web PWA + Android |
| Backend | Golang + Fiber + robfig/cron | Cron sync server |
| Database | Supabase (PostgreSQL) | Data + Auth + REST API |
| Images | Wallhaven API v1 | Source wallpapers |
| Hosting | Render (backend) + Static (web) | Deployment |

## Project Structure

```
vivek_app/
├── backend/              # Golang sync server
│   ├── main.go           # Entry: Fiber + Cron + routes
│   ├── config/           # Env loading + validation
│   ├── handlers/         # Wallhaven -> Supabase sync logic
│   └── models/           # API + DB data structs
├── app/                  # Flutter client
│   ├── lib/
│   │   ├── main.dart     # App entry + Supabase init
│   │   ├── screens/      # Home, Detail, Wishlist, Settings
│   │   ├── widgets/      # Grid, Cards, Tabs, Auth sheet
│   │   ├── services/     # Supabase CRUD + heart actions
│   │   ├── models/       # Wallpaper data class
│   │   └── utils/        # Color parsing utilities
│   └── test/             # 109 tests (widget + unit)
├── sql/                  # Database migrations
│   ├── 001_schema.sql    # Tables
│   ├── 002_rls.sql       # Row Level Security
│   └── 003_indexes.sql   # Performance indexes
└── docs/                 # Detailed documentation
```

## Quick Start

### Prerequisites

- Go 1.22+
- Flutter 3.x
- Supabase account ([supabase.com](https://supabase.com))
- Wallhaven API key ([get yours here](https://wallhaven.cc/settings#api) | [API docs](https://wallhaven.cc/help/api))

### 1. Set Up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Enable **Email/Password** auth (Authentication -> Providers)
3. Enable **Google OAuth** auth (requires [Google Cloud Console](https://console.cloud.google.com) setup)
4. Run these SQL files in order via **SQL Editor**:
   - `sql/001_schema.sql`
   - `sql/002_rls.sql`
   - `sql/003_indexes.sql`

### 2. Start the Backend

```bash
cd backend
cp .env.example .env       # Fill in your keys
go run .                    # Starts on port 3000
```

Trigger a manual sync: `curl -X POST http://localhost:3000/api/sync`

### 3. Start the Flutter App

```bash
cd app
cp .env.example .env        # Fill in Supabase URL + Anon Key
flutter pub get
flutter run -d chrome
```

### 4. Run Tests

```bash
# Flutter (109 tests)
cd app && flutter test

# Go (30 tests)
cd backend && go test ./...
```

## Features

| Feature | Status | Description |
|---------|--------|-------------|
| Staggered Grid | Done | Responsive 2/3/4 column grid with aspect-ratio cards |
| Category Tabs | Done | Trending, Anime, AMOLED, Desktop, Mobile |
| Detail Screen | Done | Full-screen view + dynamic color theming |
| Glassmorphism | Done | Blurred specs card with resolution + file size |
| Wishlist | Done | Heart icon, auth-gated, swipe-to-delete |
| Auth | Done | Google OAuth + Email/Password bottom sheet |
| Image Caching | Done | CachedNetworkImage for thumbnails + full-res |
| Pull to Refresh | Done | RefreshIndicator on home + wishlist |
| PWA | Done | Standalone mode, black theme |
| Android Support | Done | Wallpaper setting permissions configured |

## Deployment

### Backend (Render)

```bash
# Push to GitHub, then on Render:
# 1. Create Web Service from repo
# 2. Set root directory to backend/
# 3. Set runtime to Docker
# 4. Add env vars: PORT, SUPABASE_URL, SUPABASE_SERVICE_KEY, WALLHAVEN_API_KEY, LOG_LEVEL
# 5. Deploy
```

### Flutter Web

```bash
cd app
flutter build web --release
# Deploy build/web/ to Netlify / GitHub Pages / Firebase Hosting
```

## Documentation

| Document | What It Covers |
|----------|---------------|
| [Master Plan](docs/PLAN.md) | Full execution checklist, phases, file manifest |
| [Architecture](docs/ARCHITECTURE.md) | System diagram, data flow, design decisions |
| [Database](docs/DATABASE.md) | Schema, RLS, indexes, query examples |
| [Backend](docs/BACKEND.md) | Sync logic, env vars, Docker, rate limits |
| [Frontend](docs/FRONTEND.md) | Screens, widgets, animations, image strategy |
| [Auth Model](docs/AUTH.md) | Auth flow diagrams, bottom sheet, security |
| [Deployment](docs/DEPLOYMENT.md) | Railway, Netlify, Android, env vars |

## License

MIT License - see [LICENSE](LICENSE)
