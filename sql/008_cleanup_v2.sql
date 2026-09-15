-- ============================================================
-- 008_cleanup_v2.sql — Updated cleanup for local-first tables
-- ============================================================

-- Update the cleanup function to protect wishlists_v2 and moodboard_items_v2
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
    )
    AND wallhaven_id NOT IN (
      SELECT wallhaven_id FROM wishlists_v2
      UNION
      SELECT wallhaven_id FROM moodboard_items_v2
    );
END;
$$;
