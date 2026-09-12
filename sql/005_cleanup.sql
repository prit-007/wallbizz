-- ============================================================
-- 005_cleanup.sql — Wallpaper retention + cleanup support
-- ============================================================

-- Index on moodboard_items.wallpaper_id for fast protected-ID lookups during cleanup.
-- The existing idx_moodboard_items_board only indexes moodboard_id.
CREATE INDEX idx_moodboard_items_wallpaper ON moodboard_items(wallpaper_id);

-- Optional: Supabase Edge Function or pg_cron schedule for automatic cleanup.
-- Run manually: SELECT cleanup_old_wallpapers();
CREATE OR REPLACE FUNCTION cleanup_old_wallpapers()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM wallpapers
  WHERE created_at < now() - interval '3 days'
    AND id NOT IN (
      SELECT wallpaper_id FROM wishlists
      UNION
      SELECT wallpaper_id FROM moodboard_items
    );
END;
$$;
