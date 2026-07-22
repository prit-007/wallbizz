# Frontend Guide

## Overview

Flutter 3.x app targeting Web (PWA) and Android simultaneously. Dark-first design with "youth-centric, premium Vogue-editorial" aesthetic. Communicates only with Supabase for browsing; search is hybrid (SFW direct to Wallhaven, NSFW through backend proxy).

## Project Structure

```
app/lib/
├── main.dart                          # Entry: dotenv → Hive → Supabase → pure black native splash
├── config/
│   ├── backend_config.dart            # Backend URL (overridable on web)
│   ├── supabase_config.dart           # .env loader
│   └── theme_config.dart              # Dark/light mode + custom VivekTheme colors
├── models/
│   ├── wallpaper.dart                 # Data class with fromMap()
│   ├── downloaded_wallpaper.dart      # Hive-compatible download metadata
│   └── moodboard.dart                 # Moodboard + MoodboardItem data classes
├── services/
│   ├── supabase_service.dart          # CRUD: wallpapers + wishlists
│   ├── wallpaper_actions.dart         # Heart tap + auth gating + pending action
│   ├── wallhaven_search.dart          # Search API: direct (SFW) + proxy (NSFW)
│   ├── download_service.dart          # Platform-specific file download with progress
│   ├── downloads_service.dart         # Hive-backed download tracking
│   └── moodboard_service.dart         # Moodboard CRUD (authenticated)
├── screens/
│   ├── splash_screen.dart             # Animated "WALLBIZZ" letter spacing → navigates to HomeScreen
│   ├── home_screen.dart               # Search bar + category tabs + staggered grid + 4-tab lazy nav
│   ├── search_screen.dart             # Full search UI with purity/sorting/filter controls
│   ├── detail_screen.dart             # Full view + swipe-down-back + tap-toggle-UI + share + moodboard
│   ├── wishlist_screen.dart           # "ARCHIVE" tab (auth-gated)
│   ├── downloads_screen.dart          # "VAULT" tab (Hive-backed local downloads)
│   ├── settings_screen.dart           # "SYSTEM" tab (dark mode, download path, account)
│   ├── wallpaper_editor_screen.dart   # Pan/zoom/rotate + set wallpaper (Android)
│   ├── verify_email_screen.dart       # Post-signup email verification
│   └── forgot_password_screen.dart    # Password reset flow
├── widgets/
│   ├── staggered_grid.dart            # Responsive GridView + pagination + shimmer skeleton
│   ├── wallpaper_card.dart            # Grid card + heart icon + entrance animation
│   ├── category_tabs.dart             # Horizontal scrolling pill bar (7 categories)
│   ├── specs_card.dart                # Glassmorphism overlay (resolution, size, color swatches)
│   ├── network_image.dart             # CORS-safe image loader (proxied on web)
│   ├── dynamic_theme.dart             # AnimatedContainer for ambient color tinting
│   ├── auth_bottom_sheet.dart         # Google + Email auth bottom sheet
│   ├── add_to_moodboard_sheet.dart    # Moodboard picker/creator bottom sheet
│   ├── moodboard_picker.dart          # Reusable moodboard selection widget
│   └── gesture_hint_overlay.dart      # First-visit swipe/tap hint overlay
└── utils/
    ├── color_utils.dart               # Hex <-> Color conversion
    └── share_utils.dart               # Watermarked share (overlays "WALLBIZZ" branding)
```

## Screens

### Home Screen
- **Search Bar**: Tappable search bar at top, navigates to SearchScreen. Responsive sizing via `LayoutBuilder`
- **CategoryTabs**: Horizontal scrollable pill bar (Trending, Anime, Nature, Cyberpunk, Space, Desktop, Mobile)
- **StaggeredGrid**: Responsive `GridView.builder` with 2/3/4 columns based on screen width
- **Lazy Tabs**: 4 tabs (DISCOVER, ARCHIVE, VAULT, SYSTEM) created on first visit via `Offstage`
- **Scroll-to-top**: Re-tapping active nav item scrolls tab content to top

### Search Screen
- **Search TextField**: Real-time search with 300ms debounce
- **Purity Chips**: SFW / Sketchy / NSFW toggle (default: SFW only, auth-gated)
- **Sorting Dropdown**: Relevance, Toplist, Date Added, Views, Favorites
- **Range Dropdown**: 1 day → 1 year
- **Category Dropdown**: All, People, Anime, People & Anime
- **Ratio Dropdown**: All, Landscape, Portrait, Square
- **Results Grid**: Staggered grid with infinite scroll
- **Hybrid Mode**: SFW → direct to Wallhaven; NSFW/Sketchy → backend proxy (JWT-gated)

### Detail Screen
- Full-screen `InteractiveViewer` with pinch-to-zoom + double-tap zoom toggle (2.5x)
- Swipe-down-to-go-back (25% threshold, disabled when zoomed)
- Tap-to-toggle-UI (hides/shows top bars + bottom panel via `AnimatedSlide`)
- Radial vignette gradient + blurred wallpaper copy with ambient color overlay
- Frosted glass top bar: back, heart (wishlist), moodboard, share (watermarked)
- Frosted glass bottom: `SpecsCard` + download button + set-as-wallpaper (Android)
- Gesture hint overlay on first visit (dismissed permanently via SharedPreferences)

### Wishlist Screen
- If authenticated: grid of saved wallpapers with swipe-to-delete
- If guest: "SIGN IN TO CURATE" prompt
- Reactive updates via `wishlistNotifier` ValueNotifier

### Downloads Screen (VAULT)
- Hive-backed grid of downloaded wallpapers
- Search/filter by wallpaper ID or resolution
- Multi-select mode (long-press) with bulk delete
- Cascading entrance animation

### Settings Screen
- Dark mode toggle (persisted via SharedPreferences)
- Download location: Pictures / Downloads / App Storage
- Account: sign in / sign out / delete account
- Connected services info

## Data Models

```dart
class Wallpaper {
  final String id, wallhavenId, urlFull, urlThumb, resolution;
  final int width, height, fileSize;
  final String primaryColor, category, sourceQuery;
  final DateTime createdAt;

  double get aspectRatio => width / height;
  String get formattedFileSize => /* KB or MB */;
  factory Wallpaper.fromMap(Map<String, dynamic> map);
}

class DownloadedWallpaper {
  final String wallhavenId, urlFull, urlThumb, resolution, fileName, filePath;
  final int width, height, fileSize;
  final String primaryColor;
  final DateTime downloadDate;
  // Hive TypeAdapter for local persistence
}

class Moodboard {
  final String id, name, userId;
  final DateTime createdAt;
  final List<MoodboardItem>? items;
}

class MoodboardItem {
  final String id, moodboardId, wallpaperId;
  final DateTime createdAt;
}
```

## Image Strategy

| Context | Image | Source | Caching |
|---------|-------|--------|---------|
| Grid card | Thumbnail | `url_thumb` | CachedNetworkImage (disk) |
| Detail screen | Full-res | `url_full` | CachedNetworkImage (disk) |

Aspect ratio calculated from `width / height` DB values before image loads -- prevents grid jumps.

## Responsive Breakpoints

| Screen Width | Grid Columns | Search Bar Height | Search Bar Padding |
|-------------|-------------|-------------------|-------------------|
| < 600px (mobile) | 2 | 44px | Compact |
| 600-900px (tablet) | 3 | 52px | Standard |
| > 900px (desktop) | 4 | 52px | Standard |

**CategoryTabs**: Item width 100, height 120 outer SizedBox, emoji fontSize 22, text fontSize 15. Uses `clipBehavior: Clip.hardEdge` on AnimatedContainer.

**StaggeredGrid Loading Skeleton**: Uses `LayoutBuilder` for responsive column count matching grid columns.

## Animations

| Element | Animation | Duration |
|---------|-----------|----------|
| WALLBIZZ title | fade + slideX | 600ms |
| Search bar | fade + slideY | 300ms |
| Category tabs | fade | 400ms |
| Nav bar | slideY | 800ms easeOutExpo |
| Grid cards | fade + slideY | 400ms (staggered) |
| Category pill select | scale + glow | 250ms easeOutCubic |
| Detail background | blur + color tint | 600ms |
| UI toggle (detail) | slide + opacity | 350ms easeInOutCubic |
| Specs card | slideY + fade | 500ms |
| Heart icon | scale bounce | 300ms |
| Download progress | fade + scale | 300-500ms |
| Moodboard sheet | slide up + fade | 350ms |
| Splash text | letter-spacing tween | 1.2s easeOutExpo |

## Tests (200 total)

| File | Tests | What |
|------|-------|------|
| `color_utils_test.dart` | 10 | hexToColor, withAlpha |
| `color_utils_edge_test.dart` | 16 | Edge cases, round-trips |
| `wallpaper_test.dart` | 12 | fromMap, aspectRatio, formattedFileSize |
| `wallpaper_extra_test.dart` | 17 | Edge cases, dates, large values |
| `wallpaper_card_test.dart` | 10 | Rendering, heart, taps |
| `specs_card_test.dart` | 10 | Resolution, file size, category, glassmorphism |
| `category_tabs_test.dart` | 8 | Rendering, taps, scroll direction |
| `dynamic_theme_test.dart` | 6 | Color application, child rendering |
| `settings_screen_test.dart` | 12 | Toggle, persistence, content |
| `search_screen_test.dart` | 15 | Search UI, purity chips, dropdowns, results, debounce |
| `home_screen_test.dart` | 7 | Search bar, navigation, responsive layout |
| `wallhaven_search_test.dart` | 23 | URL builders, response parser, direct/proxy paths |
| `widget_test.dart` | 1 | App initialization |
| *(Go backend)* | 38 | Models, sync, search, config |

Run: `cd app && flutter test`
