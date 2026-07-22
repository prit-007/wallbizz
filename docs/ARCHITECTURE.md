# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────┐
│                    FLUTTER CLIENT                    │
│  (Web PWA + Android)                                │
│                                                     │
│  Home Screen ──> Search Bar ──> SearchScreen         │
│  Category Tabs ──> Staggered Grid                   │
│  Detail Screen ──> Dynamic Theme + Glassmorphism    │
│  Wishlist Screen ──> Auth Bottom Sheet (gated)      │
└──────┬──────────────────────────┬───────────────────┘
       │                          │
       │ Supabase Anon Key        │ SFW (purity=100): direct to Wallhaven
       │ (RLS enforced)           │ NSFW/Sketchy: via backend proxy
       │ READ wallpapers /        │ (requires auth JWT)
       │ CRUD wishlists           │
       ▼                          ▼
┌──────────────────┐   ┌─────────────────────────────────────────────┐
│    SUPABASE      │   │              WALLHAVEN API v1               │
│ wallpapers       │   │  Direct (SFW): Flutter ──────────────────>  │
│ wishlists        │   │  Proxied (NSFW): Flutter ─> Golang ──────>  │
│ PostgREST REST   │   │  5 sync queries: Trending|Anime|AMOLED|...  │
└──────┬───────────┘   └─────────────────────────────────────────────┘
       │ Supabase Service Key
       │ (bypasses RLS)
       │ UPSERT wallpapers (twice daily)
       ▼
┌─────────────────────────────────────────────────────┐
│              GOLANG BACKEND (Render)                 │
│  Fiber Server + robfig/cron + net/http Client        │
│  POST /api/sync (manual trigger)                    │
│  POST /api/search (NSFW/Sketchy proxy, JWT-gated)   │
└─────────────────────┬───────────────────────────────┘
                      │ HTTP GET
                      ▼
┌─────────────────────────────────────────────────────┐
│              WALLHAVEN API v1                        │
│  Sync: 5 queries per sync, 24 results each          │
│  Search: user query forwarded with API key           │
└─────────────────────────────────────────────────────┘
```

## Complete Workflow

### 1. Backend: Sync Engine (Golang — `backend/main.go:29-36`)

The backend is a background data pipeline, not a real-time API. Flutter never calls the Golang server.

A `robfig/cron` scheduler fires at **2 AM and 2 PM UTC** daily. Each trigger calls `FetchAndSyncWallpapers()` which loops through 7 categories:

| # | Category | Wallhaven Query Params |
|---|----------|----------------------|
| 1 | trending | `?apikey=...&purity=100&sorting=toplist&topRange=3M` |
| 2 | anime | `?apikey=...&purity=100&sorting=toplist&topRange=3M&q=anime&categories=010` |
| 3 | nature | `?apikey=...&purity=100&sorting=toplist&topRange=3M&q=nature&categories=111` |
| 4 | cyberpunk | `?apikey=...&purity=100&sorting=toplist&topRange=3M&q=cyberpunk&categories=111` |
| 5 | space | `?apikey=...&purity=100&sorting=toplist&topRange=3M&q=space&categories=111` |
| 6 | desktop | `?apikey=...&purity=100&sorting=toplist&topRange=3M&ratios=16x9,16x10` |
| 7 | mobile | `?apikey=...&purity=100&sorting=toplist&topRange=3M&ratios=9x16,10x16` |

- 7 queries × 24 results = **168 wallpapers per sync run**
- 2 runs/day = 336 wallpapers/day (with overlap deduplication via upsert)

Per category flow (`handlers/sync.go:43-101`):
1. Build URL: `https://wallhaven.cc/api/v1/search?apikey=...&purity=100&sorting=toplist&topRange=3M&{category_params}`
2. HTTP GET with **30s timeout**
3. Parse JSON response into `WallhavenResponse` struct
4. Map each wallpaper to `WallpaperInsert` — extracting `id`, `path` (full-res URL), `thumbs.original` (thumbnail), `resolution`, `width`, `height`, `file_size`, `colors[0]` (primary color), `category`, and stamping `source_query` = category name
5. POST batch to Supabase REST (`/rest/v1/wallpapers`) with header **`Prefer: resolution=merge-duplicates`** — PostgREST upsert. If `wallhaven_id` already exists, it updates; otherwise inserts.

**Manual trigger**: `POST /api/sync` fires the same sync in a goroutine (returns immediately). Used for initial data population and testing.

---

### 2. App Launch (`app/lib/main.dart:8-18`)

```
1. dotenv.load()           — reads app/.env (SUPABASE_URL, SUPABASE_ANON_KEY)
2. Supabase.initialize()   — connects Flutter to Supabase, sets up auth listener
3. runApp(VivekApp())      — dark theme, Inter font, black scaffold
4. home: HomeScreen()      — lands on the home tab
```

Initial state (`home_screen.dart:16-17`):
- `_selectedCategory = 'trending'`
- `_currentNavIndex = 0` (Home tab)

Layout:

```
+---------------------------------------+
|  [Search Bar — tap opens SearchScreen]|
|  🔍 Search wallpapers...             |
+---------------------------------------+
|  [CategoryTabs — horizontal scroll]   |
|  🔥 Trending | 🌸 Anime | 🌿 Nature  |
|  🤖 Cyberpunk | 🚀 Space | 🖥️ Desktop | 📱 Mobile |
+---------------------------------------+
|  [StaggeredGrid — responsive columns] |
|  +------+------+------+------+        |
|  | card | card | card | card |        |
|  +------+------+------+------+        |
|  | card    | card | card |            |
|  +---------+------+------+            |
|  | card | card | card | card |        |
|  +------+------+------+------+        |
+---------------------------------------+
|  🏠 Home  |  ❤️ Collection  | ⚙️ Settings |
+---------------------------------------+
```

---

### 3. Loading Wallpapers — First Render

`staggered_grid.dart:28-32` — `initState()` calls `_loadWallpapers()`:

```dart
SupabaseService.instance.fetchWallpapers(
  category: 'trending',
  page: 0,
  pageSize: 24,          // matches Wallhaven's page size
)
```

What Flutter sends to Supabase (`supabase_service.dart:21-49`):

```
GET https://{project}.supabase.co/rest/v1/wallpapers
    ?select=*&order=created_at.desc&source_query=eq.trending
Headers:
    apikey: {anon_key}
    Authorization: Bearer {anon_key}
    Range: 0-23               ← PostgREST pagination
```

- `select=*` — all columns
- `order=created_at.desc` — newest first
- `source_query=eq.trending` — category filter
- `Range: 0-23` — PostgREST pagination (items 0 through 23)

Response parsed into `Wallpaper` model via `Wallpaper.fromMap()`.

After data arrives (`staggered_grid.dart:67-74`):
```dart
_wallpapers.addAll(newWallpapers);  // append
_page++;                             // advance to page 1
_hasMore = newWallpapers.length == 24;  // if < 24, end reached
_isLoading = false;
```

**Grid rendering** (line 100-141): `LayoutBuilder` detects screen width:
- > 900px = 4 columns
- > 600px = 3 columns
- ≤ 600px = 2 columns

`GridView.builder` creates `WallpaperCard` for each wallpaper. If `_hasMore`, an extra item shows a `CircularProgressIndicator` spinner.

---

### 4. Scrolling & Pagination (Infinite Scroll)

`staggered_grid.dart:31` — `ScrollController` attached to `GridView`.

`_onScroll()` (line 77-82):
```dart
if (scrollPosition >= maxScrollExtent - 200) {
  _loadWallpapers();  // trigger next page
}
```

Pagination math:
| Page | Range Header | Items |
|------|-------------|-------|
| 0 | `Range: 0-23` | 1-24 |
| 1 | `Range: 24-47` | 25-48 |
| 2 | `Range: 48-71` | 49-72 |
| … | … | continues until Supabase returns < 24 |

**`_isLoading` guard** (line 58): prevents multiple simultaneous requests.

**Pull-to-refresh** (line 84-91): `RefreshIndicator` wraps the grid. Pulling clears all data and reloads from page 0.

---

### 5. Switching Categories

`category_tabs.dart:40-41` — tapping a category calls:
```dart
widget.onCategorySelected(cat['value']);  // e.g. 'anime'
```

`home_screen.dart:62` — `setState(() => _selectedCategory = 'anime')`

`staggered_grid.dart:35-40` — `didUpdateWidget()` detects change:
```dart
if (oldCategory != newCategory) {
  _resetAndLoad();  // clear list, reset page to 0, reload
}
```

`_resetAndLoad()` (line 48-55):
```dart
_wallpapers.clear();
_page = 0;
_hasMore = true;
_loadWallpapers();  // fetches with new source_query filter
```

Supabase sees the `source_query=eq.{category}` filter change and returns different wallpapers.

---

### 6. Tapping a Wallpaper Card

`staggered_grid.dart:134`:
```dart
onTap: () => widget.onWallpaperTap?.call(_wallpapers[index])
```

`home_screen.dart:68-73`:
```dart
onWallpaperTap: (wallpaper) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DetailScreen(wallpaper: wallpaper)),
  );
}
```

**Detail Screen** (`detail_screen.dart:18-150`):
1. `DynamicTheme` wraps everything — extracts `wallpaper.primaryColor`, creates `AnimatedContainer` that tints the background
2. Full-resolution image via `CachedNetworkImage(imageUrl: wallpaper.urlFull)` — this is the `path` field from Wallhaven (e.g. `https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg`)
3. Gradient overlay at bottom (300px tall, transparent → 80% black)
4. Back button (top-left circle)
5. Bottom column:
   - **SpecsCard** — glassmorphism (`BackdropFilter` blur) showing resolution, file size, category
   - **Download Wallpaper** button — opens `wallpaper.urlFull` in external browser via `url_launcher`
   - **Set as Wallpaper** button — Android-only (`!kIsWeb`), currently shows a snackbar

---

### 7. Heart Tap / Wishlist / Auth Flow

No auth screen exists. Auth only appears when the user tries to save.

`wallpaper_actions.dart:13-28` — `handleHeartTap()`:
```dart
final user = Supabase.instance.client.auth.currentUser;

if (user == null) {
  // Guest: store pending wallpaper, show auth
  _pendingWallpaper = wallpaper;
  _onPendingComplete = onComplete;
  showAuthBottomSheet(context);
  return;
}
// Authed: toggle wishlist directly
_toggleWishlist(user.id, wallpaper, onComplete);
```

`_toggleWishlist()` (line 34-48):
1. Check if wallpaper is already in user's wishlist (`SupabaseService.isInWishlist`)
2. If yes → remove. If no → add.
3. Call `onComplete` callback (refreshes UI)

After successful auth (`auth_bottom_sheet.dart:62-64`):
```dart
WallpaperActions.onAuthSuccess();  // executes pending save
Navigator.of(context).pop();       // closes bottom sheet
```

`WallpaperActions.onAuthSuccess()` (line 52-59):
```dart
static void onAuthSuccess() {
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null && _pendingWallpaper != null) {
    _toggleWishlist(user.id, _pendingWallpaper!, _onPendingComplete);
    _pendingWallpaper = null;
    _onPendingComplete = null;
  }
}
```

The full `Wallpaper` object is stored as `_pendingWallpaper` — not just an ID. After auth, the exact wallpaper the user tried to save gets saved, no data loss.

---

### 8. Wishlist Screen

`wishlist_screen.dart` — bottom nav tab "My Collection":
1. Gets current user ID from Supabase auth
2. Calls `SupabaseService.fetchWishlist(userId)`:
   ```
   GET /rest/v1/wishlists?user_id=eq.{userId}&select=wallpapers(*),created_at&order=created_at.desc
   ```
   This is a **PostgREST join** — fetches wishlists joined with wallpapers table
3. Renders each wallpaper in a grid with swipe-to-delete (`Dismissible`)
4. Uses `CachedNetworkImage` + `ClipRRect` for rounded clipping + caching
5. Listens to auth stream — if user signs out, shows empty state with sign-in prompt

---

### 9. Search Flow (Hybrid Direct + Proxy)

Search uses a hybrid approach: SFW-only queries go directly from Flutter to Wallhaven (no backend needed), while NSFW/Sketchy queries are proxied through the backend with JWT verification.

**Search entry point** (`home_screen.dart`): Search bar at top of HomeScreen navigates to SearchScreen on tap.

**SearchScreen** (`screens/search_screen.dart`):
- TextField with debounced search (300ms)
- Purity chips: SFW / Sketchy / NSFW (default: SFW only)
- Sorting, date range, category, and ratio dropdowns
- Staggered grid results with infinite scroll
- Accepts `isAuthenticated`, `backendBase`, `accessToken` params for testability

**SFW path (direct)**:
```
Flutter ──HTTP GET──> wallhaven.cc/api/v1/search?q=...&purity=100&apikey=...
```
No auth required. `WallhavenSearch.searchPublic()` builds the URL and parses the response.

**NSFW/Sketchy path (backend proxy)**:
```
Flutter ──POST /api/search (JWT header)──> Backend ──GET wallhaven.cc──> Wallhaven API
```
1. Flutter sends search params + `Authorization: Bearer {access_token}` to `/api/search`
2. Backend extracts JWT, verifies against Supabase (`https://{project}.supabase.co/auth/v1/user`)
3. If valid, backend forwards the query to Wallhaven API with `WALLHAVEN_API_KEY`
4. Backend returns Wallhaven response to Flutter
5. `WallhavenSearch.searchAuthenticated()` handles this path

**Response parsing** (`wallhaven_search.dart`):
- `SearchResult` class maps Wallhaven response to Flutter-friendly objects
- Returns list of `SearchResult` with id, url, thumbnail, resolution, purity, category

**Backend search endpoint** (`handlers/search.go`):
- Route: `POST /api/search`
- Validates JWT via Supabase Auth API
- Proxies query params to Wallhaven API
- Returns raw Wallhaven JSON response

### 10. Image Loading Strategy

| Context | URL Used |
|---------|----------|
| Grid thumbnail | `url_thumb` = `thumbs.original` from Wallhaven |
| Detail full-screen | `url_full` = `path` from Wallhaven |
| Download button | `url_full` |

Both use `CachedNetworkImage` which caches to disk automatically.

---

### 11. Complete Data Flow Summary

```
DAILY (2 AM / 2 PM UTC):
  Cron fires
    → 5 HTTP GETs to wallhaven.cc/api/v1/search (one per category)
    → Parse JSON, map to WallpaperInsert structs
    → POST batch to Supabase /rest/v1/wallpapers (upsert)
    → 120 wallpapers updated/inserted

WHEN USER OPENS APP:
  Flutter reads .env → connects to Supabase
    → HomeScreen renders with search bar + "trending" selected
    → StaggeredGrid calls SupabaseService.fetchWallpapers(category: 'trending', page: 0)
    → Supabase returns 24 wallpapers (via PostgREST Range header)
    → GridView renders 24 WallpaperCards with thumbnails

WHEN USER SEARCHES (SFW):
  SearchScreen → WallhavenSearch.searchPublic(query, purity: 100)
    → Direct HTTP GET to wallhaven.cc/api/v1/search
    → Parse response into SearchResult list
    → Display in staggered grid

WHEN USER SEARCHES (NSFW/Sketchy):
  SearchScreen → WallhavenSearch.searchAuthenticated(query, purity: 010|110)
    → POST /api/search with JWT header
    → Backend verifies JWT, forwards to Wallhaven API
    → Returns response to Flutter
    → Display in staggered grid

WHEN USER SCROLLS:
  ScrollController detects 200px from bottom
    → _loadWallpapers() called with page 1
    → Supabase returns next 24 wallpapers
    → Appended to list, grid rebuilds

WHEN USER SWITCHES CATEGORY:
  CategoryTabs callback → setState
    → didUpdateWidget detects category change
    → _resetAndLoad() clears grid, fetches page 0 with new source_query filter

WHEN USER TAPS CARD:
  Navigator pushes DetailScreen(wallpaper: ...)
    → Full-res image loads via CachedNetworkImage
    → DynamicTheme tints background to wallpaper's primary_color
    → SpecsCard shows resolution + file size

WHEN USER TAPS HEART (guest):
  WallpaperActions.handleHeartTap()
    → Stores pending Wallpaper object
    → Shows AuthBottomSheet (Google or Email/Password)
    → On auth success → pending wallpaper saved to wishlists table

WHEN USER TAPS HEART (authed):
  WallpaperActions.handleHeartTap()
    → Checks isInWishlist → toggles add/remove
    → SupabaseService POST or DELETE to /rest/v1/wishlists

WHEN USER OPENS COLLECTION:
  WishlistScreen loads
    → Fetches wishlists joined with wallpapers for current user
    → Renders grid with swipe-to-delete
```

---

## Hybrid Category Strategy

Wallhaven's search endpoint returns `category` (anime/general) but not detailed tags. Instead of making per-wallpaper requests (rate-limited to 45/min), we use a hybrid approach:

| Category | Wallhaven Query | DB `source_query` | How It Filters |
|----------|----------------|-------------------|----------------|
| Trending | `sorting=toplist` | `trending` | Broad SFW toplist |
| Anime | `q=anime&categories=010` | `anime` | Anime-specific |
| Nature | `q=nature&categories=111&purity=100` | `nature` | Nature/landscape |
| Cyberpunk | `q=cyberpunk&categories=111&purity=100` | `cyberpunk` | Cyberpunk aesthetic |
| Space | `q=space&categories=111&purity=100` | `space` | Space/astronomy |
| Desktop | `ratios=16x9,16x10` | `desktop` | Landscape ratios |
| Mobile | `ratios=9x16,10x16` | `mobile` | Portrait ratios |

---

## What's NOT There (Deliberate)

- **No real-time updates.** App reads stale data from Supabase. New wallpapers appear only after the next cron sync.
- **No tags.** Wallhaven's search API doesn't return tags in bulk (only individual wallpaper endpoints do, rate-limited to 45/min). We use `source_query` as a proxy.
- **No user-generated content.** Only Wallhaven wallpapers exist in the database.
- **No native wallpaper setting.** "Set as Wallpaper" button shows a snackbar — requires platform channels for a real Android implementation.

---

## Rate Limit Safety

| Operation | Frequency | Calls/day | Limit | Utilization |
|-----------|-----------|-----------|-------|-------------|
| Backend → Wallhaven (sync) | 2× daily × 7 queries | 14 | 45/min | 0.52% |
| Backend → Wallhaven (search proxy) | Per user search | Variable | 45/min | Depends on usage |
| Flutter → Wallhaven (SFW search) | Per user search | Variable | 45/min | Depends on usage |
| Flutter → Supabase | Per user session | Unlimited | None | N/A |

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `width`/`height` as integers | Flutter grid needs aspect ratio before image loads |
| Direct HTTP to Supabase (not supabase-go) | Simpler, zero dependency risk |
| `source_query` instead of tags | Wallhaven search API doesn't return tags in bulk |
| Supabase over direct PostgreSQL | Instant PostgREST API + built-in Auth + RLS |
| `GridView.builder` (not MasonryGridView) | MasonryGridView needs pre-calculated heights that conflict with dynamic image loading |
| Store full Wallpaper object as `_pendingWallpaper` | After auth, exact wallpaper is saved — no data loss |
| Upsert via `Prefer: resolution=merge-duplicates` | PostgREST mechanism; driven by `wallhaven_id` UNIQUE constraint |
| Hybrid search (SFW direct, NSFW proxy) | SFW queries don't need auth; NSFW requires backend proxy to hide API key and enforce JWT |
