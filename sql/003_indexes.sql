-- ============================================================
-- 003_indexes.sql — Performance indexes for fast queries
-- ============================================================

-- Speeds up the "Latest Wallpapers" feed on the home screen.
-- wallpapers ORDER BY created_at DESC LIMIT 24
CREATE INDEX idx_wallpapers_created_at ON wallpapers(created_at DESC);

-- Speeds up category filtering from the Flutter client.
-- wallpapers WHERE source_query = 'anime' ORDER BY created_at DESC
CREATE INDEX idx_wallpapers_category ON wallpapers(source_query);

-- Speeds up loading a specific user's wishlist.
-- wishlists WHERE user_id = '<uuid>'
CREATE INDEX idx_wishlists_user_id ON wishlists(user_id);

-- Speeds up the wishlist screen query (JOIN on wallpaper_id).
-- wishlists JOIN wallpapers ON wishlists.wallpaper_id = wallpapers.id
CREATE INDEX idx_wishlists_wallpaper_id ON wishlists(wallpaper_id);
