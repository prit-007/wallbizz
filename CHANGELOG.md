# Changelog

All notable changes to Wallbizz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.1.0] - 2025-01-01

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
