# Changelog

All notable changes to Wallbizz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
