# Backend Guide

## Overview

Golang backend that syncs wallpapers from Wallhaven to Supabase twice daily. Lightweight Fiber HTTP server with robfig/cron scheduler. Runs on Render.

## Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `PORT` | Fiber server port | No (default: 3000) |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_SERVICE_KEY` | Service Role Key (bypasses RLS) | Yes |
| `WALLHAVEN_API_KEY` | Wallhaven API key ([get yours here](https://wallhaven.cc/settings#api)) | Yes |

The backend will `log.Fatal` on startup if any required variable is missing. API docs: https://wallhaven.cc/help/api

## Project Structure

```
backend/
├── main.go                 # Entry: Fiber + Cron + routes
├── config/config.go        # Env loading + validation
├── handlers/
│   ├── sync.go             # Core sync: Wallhaven -> Supabase
│   └── search.go           # /api/search proxy: JWT verify + Wallhaven forward
├── models/wallpaper.go     # Data structs
├── Dockerfile              # Multi-stage build
├── .env.example
├── go.mod / go.sum
└── *_test.go               # 38 tests
```

## Sync Logic

### Category Queries

| Category | Wallhaven Params | `source_query` |
|----------|-----------------|----------------|
| Trending | `sorting=toplist&topRange=3M` | `trending` |
| Anime | `q=anime&categories=010` | `anime` |
| Nature | `q=nature&categories=111&purity=100` | `nature` |
| Cyberpunk | `q=cyberpunk&categories=111&purity=100` | `cyberpunk` |
| Space | `q=space&categories=111&purity=100` | `space` |
| Desktop | `ratios=16x9,16x10` | `desktop` |
| Mobile | `ratios=9x16,10x16` | `mobile` |

All queries: `purity=100` (SFW only), `sorting=toplist` (highest quality), `topRange=3M` (3-month toplist window).

### Flow

```
1. Cron triggers (2 AM / 2 PM UTC)
2. For each category in categoryQueryMap:
   a. HTTP GET wallhaven.cc/api/v1/search?{params}
   b. Parse JSON -> []WallhavenImage
   c. Map to []WallhavenInsert (with source_query = category)
   d. POST to Supabase REST /rest/v1/wallpapers
      Header: Prefer: resolution=merge-duplicates (upsert)
3. Log results
```

### HTTP Client

Shared `httpClient` with 30s timeout. All outbound calls (Wallhaven + Supabase) use it.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/health` | Health check |
| `POST` | `/api/v1/sync` | Trigger immediate sync (returns immediately, sync runs in goroutine) |
| `GET` | `/api/v1/search` | Proxy NSFW/Sketchy search to Wallhaven (requires valid Supabase JWT) |
| `GET` | `/api/v1/proxy-image` | Bypass CORS for Flutter web image loading (whitelisted hosts only) |
| `GET` | `/swagger/*` | Swagger UI |

### Search Endpoint (`/api/v1/search`)

Proxies NSFW and Sketchy purity searches from Flutter to Wallhaven API. Required because NSFW content requires the API key, which must not be embedded in the Flutter client.

**Request:**
```
GET /api/v1/search
Headers:
  Authorization: Bearer {supabase_access_token} (optional)
Query Params:
  q: search query
  purity: "010" (sketchy) or "110" (nsfw+sketchy)
  sorting: relevance | toplist | date_added | views | favorites
  topRange: 1d | 3d | 1w | 1M | 3M | 6M | 1y (if sorting=toplist)
  categories: 100 | 010 | 110 | 001
  ratios: landscape | portrait | square
  page: 1
```

**Flow:**
1. Extract JWT from `Authorization` header
2. Verify JWT against Supabase Auth API (`GET /auth/v1/user`)
3. If invalid → return 401
4. If valid → forward query params to `wallhaven.cc/api/v1/search` with `WALLHAVEN_API_KEY`
5. Return raw Wallhaven JSON response to Flutter

**Note:** SFW-only searches (purity=100) should go directly from Flutter to Wallhaven API (no backend needed). The `WALLHAVEN_API_KEY` is only used server-side for NSFW/proxied requests.

## Docker

Multi-stage build for minimal image (~10MB):

```dockerfile
FROM golang:1.22-alpine AS builder   # Build
FROM gcr.io/distroless/static-debian12  # Runtime
```

## Rate Limit Safety

- 7 queries per sync run
- 2 sync runs per day = 14 API calls/day
- Wallhaven limit: 45/minute
- **Utilization: 0.52%**

## Tests (38 total)

| Package | Tests | Coverage |
|---------|-------|----------|
| `config` | 6 | getEnv fallback, empty string, Config struct |
| `handlers` | 25 | Upsert headers/body/errors, URL path, batch sizes, category queries, search proxy JWT verification, search forwarding, error responses |
| `models` | 7 | Response parsing, empty data, zero dims, large values, JSON keys |

Run: `cd backend && go test ./...`
