# Frontend Guide

## Overview

Flutter 3.x app targeting Web (PWA) and Android simultaneously. Dark-first design with "youth-centric, premium Vogue-editorial" aesthetic. Communicates only with Supabase -- never touches Wallhaven directly.

## Project Structure

```
app/lib/
├── main.dart                          # Entry + Supabase init + dark theme
├── config/supabase_config.dart        # .env loader
├── models/wallpaper.dart              # Data class with fromMap()
├── services/
│   ├── supabase_service.dart          # CRUD: wallpapers + wishlists
│   ├── wallpaper_actions.dart         # Heart tap + auth gating + pending action
│   └── wallhaven_search.dart          # Search API: direct (SFW) + proxy (NSFW)
├── screens/
│   ├── home_screen.dart               # Search bar + category tabs + staggered grid
│   ├── search_screen.dart             # Full search UI with purity/sorting/filter controls
│   ├── detail_screen.dart             # Full view + dynamic theming
│   ├── wishlist_screen.dart           # "My Collection" tab
│   └── settings_screen.dart           # Dark/Light mode toggle
├── widgets/
│   ├── staggered_grid.dart            # Responsive GridView + pagination + loading skeleton
│   ├── wallpaper_card.dart            # Grid card + heart icon + animation
│   ├── category_tabs.dart             # Horizontal scrolling category cards
│   ├── specs_card.dart                # Glassmorphism overlay
│   ├── auth_bottom_sheet.dart         # Google + Email auth
│   └── dynamic_theme.dart             # AnimatedContainer for color tinting
└── utils/color_utils.dart             # Hex <-> Color conversion
```

## Screens

### Home Screen
- **Search Bar**: Tappable search bar at top, navigates to SearchScreen. Responsive sizing via `LayoutBuilder` (44px compact, 52px large when `maxWidth < 600`)
- **CategoryTabs**: Horizontal scrollable cards (Trending, Anime, AMOLED, Desktop, Mobile)
- **StaggeredGrid**: Responsive `GridView.builder` with 2/3/4 columns based on screen width
- **Navigation**: Bottom bar with Home / My Collection / Settings

### Search Screen
- **Search TextField**: Real-time search with 300ms debounce
- **Purity Chips**: SFW / Sketchy / NSFW toggle (default: SFW only)
- **Sorting Dropdown**: Relevance, Toplist, Date Added, Views, Favorites
- **Range Dropdown**: 1 day, 3 days, 1 week, 1 month, 3 months, 6 months, 1 year
- **Category Dropdown**: All, People, Anime, People & Anime
- **Ratio Dropdown**: All, Landscape, Portrait, Square
- **Results Grid**: Staggered grid with infinite scroll
- **Hybrid Mode**: SFW queries go direct to Wallhaven; NSFW/Sketchy queries go through backend proxy (requires auth)
- **Params**: Accepts `isAuthenticated`, `backendBase`, `accessToken` for testability

### Detail Screen
- Full-screen `CachedNetworkImage` loading `url_full`
- `DynamicTheme`: AnimatedContainer tinted with 10% of wallpaper's `primary_color`
- `SpecsCard`: Glassmorphism card (BackdropFilter + blur) showing resolution, file size, category
- Download button (web: url_launcher, Android: native)

### Wishlist Screen
- If authenticated: grid of saved wallpapers with swipe-to-delete
- If guest: "Sign in to view your collection" prompt
- Auth state listener refreshes on sign-in/sign-out

### Settings Screen
- Dark mode toggle (persisted via SharedPreferences)
- About section with version info

## Data Model

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
| Grid cards | fade + slideY | 400ms |
| Category tabs | scale + glow | 200ms |
| Detail background | color transition | 600ms |
| Specs card | slideY + fade | 500ms |
| Heart icon | scale bounce | 300ms |

## Tests (162 total)

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

Run: `cd app && flutter test`
