# Wallbizz — App Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP (Web + Android)           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │ Home     │ │ Search   │ │ Download │ │ Settings  │  │
│  │ Screen   │ │ Screen   │ │ Screen   │ │ Screen    │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └─────┬─────┘  │
│       │            │            │              │        │
│  ┌────▼────────────▼────────────▼──────────────▼─────┐  │
│  │              Services Layer                        │  │
│  │  SupabaseService  WallhavenSearch  DownloadService │  │
│  │  WallpaperActions  GalleryService  HistoryService  │  │
│  └───────────────────────┬───────────────────────────┘  │
│                          │                               │
│         ┌────────────────▼────────────────┐              │
│         │        http package             │              │
│         │  (direct REST, no supabase SDK) │              │
│         └────────┬────────────┬───────────┘              │
└──────────────────┼────────────┼──────────────────────────┘
                   │            │
     ┌─────────────▼─┐    ┌────▼──────────────┐
     │  Supabase     │    │  Go Backend       │
     │  (Postgres)   │    │  (Render.com)     │
     │  + REST API   │    │  Fiber HTTP       │
     │  + Auth       │    │  + robfig/cron    │
     └───────────────┘    └────┬──────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Wallhaven API      │
                    │  (wallhaven.cc)     │
                    └─────────────────────┘
```

---

## How Each Screen Works

### 1. Home Screen (`home_screen.dart`)
- **Route:** `/` (initial route)
- **State:** `_selectedCategory` (default `'trending'`), `_currentNavIndex` (default `0`)
- **Layout:** Custom dock-style bottom navigation pill + lazy `Offstage` tabs (4 tabs: DISCOVER, ARCHIVE, VAULT, SYSTEM)
- **Home Tab:** `CategoryTabs` horizontal pill bar (Trending, Anime, Nature, Cyberpunk, Space, Desktop, Mobile) above a `StaggeredGrid` that loads wallpapers filtered by `source_query = selected_category` from Supabase REST API
- **Category change:** Triggers `setState` on `_selectedCategory`, rebuilds `StaggeredGrid` with a new `ValueKey`, causing a fresh fetch from page 1
- **Lazy tab loading:** Tabs are created on first visit via `_tabWidgets[index] ??= _buildTabContent(index)` and kept alive via `Offstage` — no `IndexedStack` cost
- **Scroll-to-top on re-tap:** Tapping the already-active nav item scrolls that tab's content to top via `ScrollController.animateTo(0)`
- **Loading:** Shimmer skeleton animation while fetching
- **Empty state:** Oswald "NO WALLPAPERS FOUND" with subtitle

### 2. Search Screen (`search_screen.dart`)
- **Route:** Pushed via `Navigator.push`
- **Search sources:**
  - **SFW queries** (user hasn't authenticated or hasn't enabled NSFW) — direct to Wallhaven API via `WallhavenSearch` class (`GET https://wallhaven.cc/api/v1/search`)
  - **NSFW/Sketchy queries** (authenticated user enables NSFW toggles) — routed through backend proxy (`GET /api/v1/search`) which forwards to Wallhaven with the user's JWT for auth-optional purity filtering
- **Features:** Trending tag cloud, search history (`HistoryService`, last 10 queries), auto-complete, pagination, purity chips (SFW/Sketchy/NSFW, shown only when authenticated)
- **Error state:** Red error icon with retry button, shows the error message from the API response
- **Auth-gated NSFW:** Gated on `heart-tap` or explicit NSFW toggle — triggers `showAuthBottomSheet`

### 3. Detail Screen (`detail_screen.dart`)
- **Route:** Pushed with wallpaper data object
- **Image display:** `InteractiveViewer` with pinch-to-zoom and double-tap zoom toggle (2.5x)
- **Background:** Radial vignette gradient + blurred wallpaper copy with ambient color overlay
- **Swipe-down-to-go-back:** Dragging the image down past 25% of screen height pops the screen; otherwise snaps back. Disabled when zoomed in.
- **Tap-to-toggle-UI:** Single tap hides/shows the top bars and bottom action panel for immersive viewing. Uses `AnimatedSlide` + `AnimatedOpacity`.
- **Gesture hint overlay:** First visit shows a subtle hint ("swipe down to go back, tap to toggle UI") that fades after a few seconds. Dismissed permanently via `SharedPreferences`.
- **Top bar:** Frosted glass back button, heart/favourite toggle, moodboard button, share button
- **Bottom area (frosted glass action strip):**
  - `SpecsCard` — resolution, file size, aspect ratio, color swatches, wallpaper ID
  - "DOWNLOAD WALLPAPER" / "DOWNLOADING..." / "DOWNLOADED" button
  - "SET AS WALLPAPER" button (non-web only) — navigates to `WallpaperEditorScreen`
- **Heart tap:** Calls `WallpaperActions.handleHeartTap()` which either toggles wishlist directly or prompts auth
- **Moodboard tap:** Shows `AddToMoodboardSheet` bottom sheet (auth-gated)
- **Share tap:** Calls `ShareUtils.shareWithWatermark()` — fetches image, overlays "WALLBIZZ" branding, shares via share sheet, cleans up temp files
- **Download:** Calls `DownloadService.downloadImage()` with progress callback shown in a glassmorphic dialog

### 4. Wishlist Screen (`wishlist_screen.dart`)
- **Route:** Tab index 1 in `IndexedStack`
- **Auth check:** On init, checks `Supabase.instance.client.auth.currentUser`
- **Unauthenticated:** Shows "SIGN IN TO CURATE" Oswald prompt with sign-in button
- **Authenticated:** Loads wishlist items from Supabase via `GET /rest/v1/wishlists?select=wallpapers(*),created_at&order=created_at.desc`
- **Reactive updates:** Listens to `SupabaseService.wishlistNotifier` (a `ValueNotifier<int>`) — when a heart is tapped anywhere in the app, the counter increments, triggering `_checkAuthAndLoad()` to re-fetch
- **Display:** Masonry staggered grid with swipe-to-delete
- **Empty state:** Oswald "YOUR WISHLIST IS EMPTY" with subtitle

### 5. Downloads Screen (`downloads_screen.dart`)
- **Route:** Tab index 2 in `IndexedStack`
- **Data source:** Hive box with `DownloadedWallpaper` objects
- **Display:** Masonry staggered grid, cascading entrance animation
- **Search:** Filter pill at top searches by wallpaper ID or resolution
- **Selection mode:** Long-press a card to enter multi-select mode, then tap to toggle; "DELETE SELECTED" button appears in the app bar
- **Delete:** Frosted glass confirmation dialog with "DELETE N ITEMS?" header
- **Tap card:** Navigates to `DownloadedDetailScreen` for full-screen view

### 6. Settings Screen (`settings_screen.dart`)
- **Route:** Tab index 3 in `IndexedStack`
- **Dark Mode:** Switch tile that toggles `ThemeConfig.setDarkMode()`
- **Download Location:** Three `AnimatedContainer` options:
  - **Pictures** — visible in gallery, persists after uninstall
  - **Downloads** — visible in Files app, persists after uninstall
  - **App Storage** — hidden from gallery, deleted with app (shows warning dialog on tap)
- **Account Section (new in v1.1):**
  - **Not logged in:** "SIGN IN" button that opens `AuthBottomSheet`
  - **Logged in:** Shows user email, "SIGN OUT" button, "DELETE ACCOUNT" button (red, with confirmation dialog)

### 7. Wallpaper Editor Screen (`wallpaper_editor_screen.dart`)
- **Route:** Pushed from detail screen's "SET AS WALLPAPER" button
- **Features:** InteractiveViewer (pan, zoom, rotate), floating rotation dock (0°/90°/180°/270°), reset button
- **Apply:** Tap the checkmark button → shows target dialog → sets wallpaper via `async_wallpaper` package (file source if local, URL source otherwise)

### 8. Auth Bottom Sheet (`auth_bottom_sheet.dart`)
- **Not a screen** — a reusable modal bottom sheet, shown from anywhere via `showAuthBottomSheet(context)`
- **Modes:** Toggles between "WELCOME BACK" (sign in) and "JOIN THE CLUB" (sign up)
- **Providers:** Google OAuth (`g_mobiledata_rounded` icon), Email/Password
- **Flow:**
  1. User fills form, submits
  2. Loading spinner shown
  3. On success: calls `WallpaperActions.onAuthSuccess()` (processes any pending wishlist toggle), dismisses sheet
  4. On email-not-confirmed: navigates to `VerifyEmailScreen`
  5. On error: shows `SnackBar` with error message

### 9. Verify Email Screen (`verify_email_screen.dart`)
- **Route:** Pushed after email sign-up or sign-in if `emailConfirmedAt` is null
- **Features:** Oswald "VERIFY YOUR EMAIL", animated pulsing mail icon, "I'VE VERIFIED MY EMAIL" button, "RESEND" link, auto-listens for `onAuthStateChange` — navigates to `_VerifiedScreen` ("ACCESS GRANTED" animated check) when confirmed

### 10. Forgot Password Screen (`forgot_password_screen.dart`)
- **Route:** Pushed from auth bottom sheet "Forgot password?" link
- **Features:** Frosted glass email input, "SEND RESET LINK" button, glowing green success card when sent, "BACK TO SIGN IN" link

---

## How Each API Endpoint Works

### `GET /api/v1/health`
- **Purpose:** Health check for monitoring
- **Response:** `{"status": "ok"}` (200 OK)

### `POST /api/v1/sync`
- **Purpose:** Manually trigger Wallhaven-to-Supabase sync
- **Auth:** Service key only (not exposed to Flutter)
- **Behavior:** Returns `{"status": "sync triggered"}` immediately (202), runs sync in a background goroutine
- **Sync process:**
  1. Iterates over 7 categories: `trending`, `anime`, `nature`, `cyberpunk`, `space`, `desktop`, `mobile`
  2. For each, calls Wallhaven API with base params (`apikey`, `purity=100`, `sorting=toplist`, `topRange=3M`) + category-specific extras
  3. Fetches 3 pages per category
  4. Upserts to Supabase `wallpapers` table via `POST /rest/v1/wallpapers` with `Prefer: resolution=merge-duplicates` header
  5. Uses `SUPABASE_SERVICE_KEY` (bypasses RLS for writes)

### `GET /api/v1/search`
- **Purpose:** Proxy search requests to Wallhaven (enables NSFW/Sketchy for authenticated users)
- **Auth:** Optional — `Authorization: Bearer <Supabase JWT>`
  - **Valid JWT:** Forwards original query params including `purity` (enables NSFW/Sketchy)
  - **Missing/invalid JWT:** Logs warning, continues proxying without auth (SFW defaults apply)
- **Query params forwarded:** `q`, `categories`, `purity`, `sorting`, `topRange`, `ratios`, `page`
- **Backend action:** Appends `apikey`, calls `GET https://wallhaven.cc/api/v1/search?...`, returns response verbatim
- **Error:** Returns 502 Bad Gateway on upstream failure

### `GET /api/v1/proxy-image?url=...`
- **Purpose:** Bypass CORS for Flutter web image loading
- **Problem:** Flutter web uses XHR for `Image.network`, Wallhaven CDN doesn't set CORS headers
- **Host whitelist:** Only `w.wallhaven.cc` (full images) and `th.wallhaven.cc` (thumbnails)
- **Behavior:** Fetches image, validates `Content-Type` starts with `image/`, sets `Cache-Control: public, max-age=86400` (24h), streams response
- **Forbidden hosts:** Returns 403 Forbidden
- **Upstream error:** Returns 502 Bad Gateway

---

## How the Overall App Runs

### Startup Sequence
1. `main.dart` loads environment variables from `.env` via `flutter_dotenv`
2. On web: `BackendConfig.init()` overrides the base URL with `BACKEND_URL` from `.env` (fallback: hardcoded `https://wallbizz.onrender.com`)
3. Initializes Hive (local storage for downloads + preferences)
4. Initializes Supabase with `AuthFlowType.pkce` and redirect URL `wallbizz://callback` (Android deep link)
5. Wraps the app in `DynamicTheme` → `VivekTheme` → `MaterialApp`
6. MaterialApp's `home` is `SplashScreen` — shows "WALLBIZZ" with animated letter spacing, then navigates to `HomeScreen`
7. Android native splash is configured pure black via `launch_background.xml` and `values/styles.xml`

### Data Flow

**Wallpaper Browsing (read path):**
```
User opens app → HomeScreen loads → StaggeredGrid fetches
→ SupabaseService.fetchWallpapers(category: "trending", page: 1)
→ GET /rest/v1/wallpapers?select=*&order=created_at.desc&source_query=eq.trending
→ Parses JSON into List<Wallpaper> → Renders WallpaperCard grid
→ User scrolls → loadMore() fetches page 2, 3, ... (infinite scroll)
```

**Wallpaper Sync (write path — backend only):**
```
Cron triggers at 2 AM / 2 PM UTC (or POST /api/v1/sync)
→ FetchAndSyncWallpapers() iterates 7 categories
→ For each category: GET https://wallhaven.cc/api/v1/search?apikey=...&q=nature&categories=111...
→ Maps WallhavenImage → WallpaperInsert
→ POST /rest/v1/wallpapers (Prefer: resolution=merge-duplicates, upsert by wallhaven_id)
```

**Wishlist Toggle (write path):**
```
User taps heart → WallpaperActions.handleHeartTap()
→ If not authenticated: store pending wallpaper → show AuthBottomSheet
→ If authenticated: SupabaseService.addToWishlist() or removeFromWishlist()
→ POST /rest/v1/wishlists (insert) or DELETE /rest/v1/wishlists?wallpaper_id=eq.xxx
→ SupabaseService.wishlistNotifier.value++ notifies listeners
→ WishlistScreen re-fetches on notification
→ StaggeredGrid updates local _wishlistedIds set optimistically
```

**Search (read path):**
```
User types query → WallhavenSearch.searchSFW() (SFW, direct to Wallhaven)
or WallhavenSearch.searchAuthenticated() (NSFW, through backend proxy)
→ Direct: GET https://wallhaven.cc/api/v1/search?q=...&categories=...
→ Proxy: GET /api/v1/search?q=... with JWT in Authorization header
→ Results rendered in search_screen.dart grid
```

**Download (write path):**
```
User taps download → DownloadService.downloadImage() with progress callback
→ Mobile: HTTP GET → stream to File in directory (Pictures/Downloads/App Storage)
→ Web: dart:html Blob → AnchorElement download
→ On complete: DownloadsService saves metadata to Hive downloads box
→ GalleryService.saveToGallery() for Pictures/Downloads targets
```

### Image Loading Strategy (CORS on Web)
- Flutter web `Image.network` uses XHR, causing CORS errors for Wallhaven's CDN
- All image URLs in `NetworkImageWidget` are rewritten through `BackendConfig.proxyImageUrl()`:
  - `w.wallhaven.cc/...` → `https://wallbizz.onrender.com/api/v1/proxy-image?url=w.wallhaven.cc/...`
  - This only applies on web (`kIsWeb` check)
  - Mobile/desktop load images directly from Wallhaven CDN

### Authentication & RLS
- **Supabase Auth** handles user management (Email + Google OAuth with PKCE)
- **Flutter uses `SUPABASE_ANON_KEY`** for all REST requests — RLS policies control access
- **Backend uses `SUPABASE_SERVICE_KEY`** for sync upserts — bypasses RLS
- **Wishlist RLS:** `((auth.uid() = user_id))` — users can only read/write their own wishlist entries
- **Wallpapers RLS:** Public read allowed, write restricted to service key

### State Management
- No external state management library (no Provider, Riverpod, BLoC)
- **Local `setState`** per screen for UI state (e.g., loading, selected category, wishlisted IDs)
- **`ValueNotifier`** for cross-tab communication: `SupabaseService.wishlistNotifier` bridges heart taps across tabs
- **`ChangeNotifier`** via `ThemeConfig.isDarkMode` for theme toggling
- **`ValueKey`** trick: changing `_selectedCategory` gives `StaggeredGrid` a new key, forcing a fresh rebuild + fetch
- **Hive** for local persistence (downloads metadata)
- **SharedPreferences** via `HistoryService` (search history, recent wallpapers, download path)
