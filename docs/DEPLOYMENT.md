# Deployment Guide

## Overview

| Component | Platform | Method |
|-----------|----------|--------|
| Golang Backend | Render.com | Dockerfile auto-build |
| Flutter Web | Static hosting | `flutter build web` |
| Supabase | Supabase Cloud | Dashboard (managed) |

## 1. Supabase Setup

### Create Project
1. [supabase.com](https://supabase.com) -> New Project
2. Choose region, set database password
3. Wait ~2 minutes for provisioning

### Get Your Keys
Go to **Settings -> API**:

| Key | Used By | Security |
|-----|---------|----------|
| Project URL | Backend + Flutter | Public |
| `anon` key | Flutter only (RLS enforced) | Public, safe |
| `service_role` key | Backend only (bypasses RLS) | SECRET |

### Enable Auth
1. **Email/Password**: Authentication -> Providers -> Enable Email
2. **Google OAuth**:
   - [Google Cloud Console](https://console.cloud.google.com) -> APIs & Services -> Credentials
   - Create OAuth 2.0 Client ID (Web application)
   - Redirect URI: `https://{ref}.supabase.co/auth/v1/callback`
   - Copy Client ID + Secret
   - Supabase Dashboard -> Authentication -> Providers -> Google -> paste -> Enable

### Run SQL Migrations
In SQL Editor, run in order:
1. `sql/001_schema.sql`
2. `sql/002_rls.sql`
3. `sql/003_indexes.sql`

## 2. Backend (Render)

### Steps
1. Push repo to GitHub
2. [Render Dashboard](https://dashboard.render.com) -> New + -> Web Service -> Connect GitHub repo
3. Set **Root Directory**: `backend`
4. Set **Runtime**: `Docker`
5. **Plan**: Free
6. Add env vars:

```
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=eyJhbG...your_service_role_key
WALLHAVEN_API_KEY=your_wallhaven_api_key  # https://wallhaven.cc/settings#api
LOG_LEVEL=info
```

7. Render auto-deploys on push to `main`
8. Note the public URL (e.g., `https://wallbizz.onrender.com`)

### Verify
```bash
curl -X POST https://wallbizz.onrender.com/api/v1/sync
# Should return: {"status":"sync triggered"}
```

### Health Check
```bash
curl https://wallbizz.onrender.com/api/v1/health
```

## 3. Flutter Web

### Build
```bash
cd app
flutter pub get
cp .env.example .env    # Fill Supabase URL + Anon Key
flutter build web --release
```

Output: `app/build/web/`

### Deploy to Netlify
1. Push to GitHub
2. Netlify -> New site from Git
3. Build command: `cd app && flutter build web --release`
4. Publish directory: `app/build/web`

### Deploy to GitHub Pages
```bash
flutter build web --release
npx gh-pages -d build/web
```

### PWA Configuration
- `display: standalone` -- opens without browser chrome
- Black theme/background for immersive feel
- "Add to Home Screen" on mobile browsers

## 4. Environment Variables Summary

### Backend `.env`
```env
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
WALLHAVEN_API_KEY=your_wallhaven_api_key
```

### Flutter App `.env`
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

**Never expose the Service Role Key to the Flutter app.**

### Wallhaven API Key
- Get yours at: https://wallhaven.cc/settings#api
- API docs: https://wallhaven.cc/help/api
- Rate limit: 45 requests/minute
- Our usage: 5 queries per sync × 2 syncs/day = 10 calls/day (0.37% utilization)

## 5. Post-Deployment Checklist

| # | Task | Verify |
|---|------|--------|
| 1 | Backend health | `curl POST /api/sync` returns success |
| 2 | Cron running | Check Render logs at 2 AM/2 PM UTC |
| 3 | Supabase has data | Query `wallpapers` table in dashboard |
| 4 | Flutter loads | Open web URL, see category tabs + grid |
| 5 | Images render | Thumbnails load via CachedNetworkImage |
| 6 | Detail works | Tap card, see full image + specs card |
| 7 | Dynamic theme | Detail background tints to wallpaper's color |
| 8 | Auth works | Tap heart -> bottom sheet -> sign in -> heart fills |
| 9 | Wishlist persists | Sign out -> sign in -> wishlist still there |
| 10 | PWA installs | Mobile browser "Add to Home Screen" works |
