-- ============================================================
-- 007_local_first.sql — Local-first wishlist & moodboard tables
-- ============================================================
-- New tables use wallhaven_id (VARCHAR) instead of UUID FK to wallpapers.
-- This allows wishlists/moodboards to work without the wallpaper existing
-- in the wallpapers table (e.g. search results not yet synced by backend).
-- Old tables are preserved for backward compatibility during migration.

-- ----------------------------------------------------------
-- WISHLISTS V2: wallhaven_id based (no FK to wallpapers)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS wishlists_v2 (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  wallhaven_id VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(user_id, wallhaven_id)
);

-- ----------------------------------------------------------
-- MOODBOARDS V2: same structure, owned by user
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS moodboards_v2 (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ----------------------------------------------------------
-- MOODBOARD ITEMS V2: wallhaven_id based (no FK to wallpapers)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS moodboard_items_v2 (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  moodboard_id UUID REFERENCES moodboards_v2(id) ON DELETE CASCADE NOT NULL,
  wallhaven_id VARCHAR(50) NOT NULL,
  added_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(moodboard_id, wallhaven_id)
);

-- ----------------------------------------------------------
-- RLS policies
-- ----------------------------------------------------------
ALTER TABLE wishlists_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE moodboards_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE moodboard_items_v2 ENABLE ROW LEVEL SECURITY;

-- Wishlists V2: user-scoped
CREATE POLICY "Users can view their own wishlists v2"
ON wishlists_v2 FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wishlists v2"
ON wishlists_v2 FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own wishlists v2"
ON wishlists_v2 FOR DELETE
USING (auth.uid() = user_id);

-- Moodboards V2: user-scoped
CREATE POLICY "Users manage their own moodboards v2"
ON moodboards_v2 FOR ALL
USING (auth.uid() = user_id);

-- Moodboard Items V2: scoped via moodboard ownership
CREATE POLICY "Users manage their moodboard items v2"
ON moodboard_items_v2 FOR ALL
USING (
  moodboard_id IN (
    SELECT id FROM moodboards_v2 WHERE user_id = auth.uid()
  )
);

-- ----------------------------------------------------------
-- Indexes
-- ----------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_wishlists_v2_user ON wishlists_v2(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_v2_whid ON wishlists_v2(wallhaven_id);
CREATE INDEX IF NOT EXISTS idx_moodboards_v2_user ON moodboards_v2(user_id);
CREATE INDEX IF NOT EXISTS idx_moodboard_items_v2_board ON moodboard_items_v2(moodboard_id);
CREATE INDEX IF NOT EXISTS idx_moodboard_items_v2_whid ON moodboard_items_v2(wallhaven_id);

-- ----------------------------------------------------------
-- Data migration: old tables → new tables
-- ----------------------------------------------------------

-- Migrate wishlists: resolve UUID → wallhaven_id
INSERT INTO wishlists_v2 (user_id, wallhaven_id, created_at)
SELECT w.user_id, wp.wallhaven_id, w.created_at
FROM wishlists w
JOIN wallpapers wp ON w.wallpaper_id = wp.id
ON CONFLICT (user_id, wallhaven_id) DO NOTHING;

-- Migrate moodboards
INSERT INTO moodboards_v2 (id, user_id, name, created_at)
SELECT id, user_id, name, created_at
FROM moodboards
ON CONFLICT (id) DO NOTHING;

-- Migrate moodboard items: resolve UUID → wallhaven_id
INSERT INTO moodboard_items_v2 (moodboard_id, wallhaven_id, added_at)
SELECT mi.moodboard_id, wp.wallhaven_id, mi.added_at
FROM moodboard_items mi
JOIN wallpapers wp ON mi.wallpaper_id = wp.id
ON CONFLICT (moodboard_id, wallhaven_id) DO NOTHING;
