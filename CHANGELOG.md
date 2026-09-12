# Changelog

All notable changes to Wallbizz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.4.5] - 2026-09-12

### Added
- 3-day wallpaper retention — old wallpapers auto-cleaned after sync
- Wishlist & moodboard protection — saved wallpapers never deleted by cleanup
- `POST /api/v1/cleanup` endpoint for manual cleanup trigger
- `CRON_SECRET` auth guard on sync and cleanup endpoints
- GitHub Actions cron — syncs every 12 hours automatically
- GitHub Actions — Flutter web deploy to GitHub Pages
- GitHub Actions — Windows build with Inno Setup installer
- `tool/build_installer.dart` — Inno Setup `.iss` script generator
- `sql/005_cleanup.sql` — cleanup function + moodboard_items index
- Moodboard delete — trash button with confirmation dialog
- Moodboard swipe-to-delete in list sheet
- Auto-add wallpaper to newly created moodboard
- Consumer-facing gh-pages landing page with features section

### Fixed
- Stale heart icon in grid — StaggeredGrid now listens to wishlistNotifier
- Swipe-to-remove using stale index in WishlistScreen
- Post-auth heart tap — pending wallpaper auto-added to wishlist
- Optimistic heart toggle — instant icon flip via onToggle callback
- Optimistic removal rollback — item re-inserted on server failure
- Moodboard screen missing export for Supabase import

### Improved
- Landing page rewritten for consumer audience (no dev jargon in hero)
- Landing page: "Try on Web" CTA, features grid, trust badges
- Download section: web-first CTA, simpler copy
- Open Graph meta tags for social sharing

## [1.4.0] - 2026-09-12

### Added
- Wallpaper swiper — swipeable gallery-style viewer
- In-app update checker — checks GitHub releases for new versions
- Recent searches with history and quick re-search
- In-app log viewer for system diagnostics
- CI/CD pipeline with split-per-ABI Android APKs (ARM, ARM64, x86_64)
- Promotional landing page
- Custom scroll behavior with smooth bouncing physics
- RepaintBoundary optimization for 60fps scrolling

### Fixed
- Android build failure on AGP 9.0 — patched async_wallpaper's wallpaper.xml in pub cache
- async_wallpaper resource conflict — replaced @mipmap/ic_launcher with system drawable
- Gradle JVM heap OOM on release builds — reduced from 8G to 4G
- Removed deprecated `android.builtInKotlin=false` and `android.newDsl=false` flags
- All 26 flutter analyze issues resolved
- All 28 failing tests fixed (235/235 passing)
- CI: .env creation from GitHub secrets
- CI: Flutter version updated to 3.44.8 for Dart SDK ^3.12.2 compatibility

### Improved
- Search screen — recent searches, better empty states
- Downloads screen — fixed double API call, async storage calculation
- All screens — RepaintBoundary for isolated repaints
- Memory-efficient image loading with cacheWidth

## [1.3.0] - 2025-06-01

### Added
- Swipeable wallpaper viewer — swipe left/right to browse wallpapers like a photo gallery
- In-memory API response caching for faster load times
- Recent searches with history and quick re-search
- In-app log viewer for system diagnostics
- Update checker — automatically checks GitHub releases for new versions
- CI/CD pipeline with split-per-ABI Android APKs
- Promotional landing page
- Custom scroll behavior — smooth bouncing physics everywhere
- RepaintBoundary optimization for 60fps scrolling

### Fixed
- Wishlist CRUD — added missing `user_id` filters on all queries
- Wishlist toggle — now shows error feedback on server failure
- Wishlist swipe-delete — now updates badge count
- Moodboard add/remove — now checks server response before updating UI
- Moodboard remove — added mounted check after async delay
- Heart toggle — optimistic UI with server-side error handling

### Improved
- Search screen — recent searches, better empty states
- Downloads screen — fixed double API call, async storage calculation
- All screens — RepaintBoundary for isolated repaints
- Memory-efficient image loading with cacheWidth
- Removed unused dependencies (octo_image, image_cropper)

## [1.0.0] - 2024-12-01

### Added
- Initial release
- Browse wallpapers from Wallhaven
- Search with purity filters (SFW/Sketchy/NSFW)
- Download wallpapers to device
- Set as wallpaper (home/lock/both)
- Wishlist with Supabase backend
- Moodboards for organizing favorites
- Dark and light themes
- Glassmorphic UI design
- Gesture controls (swipe-down-to-go-back, tap-to-toggle-UI, double-tap-to-zoom)
