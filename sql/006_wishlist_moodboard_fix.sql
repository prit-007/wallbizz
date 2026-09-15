-- ============================================================
-- 006_wishlist_moodboard_fix.sql — Allow Flutter to upsert wallpapers for wishlist/moodboard
-- ============================================================

-- Authenticated users can insert/update wallpapers (needed when search results
-- reference wallpapers not yet synced by the backend).
CREATE POLICY "Authenticated users can upsert wallpapers"
ON wallpapers FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can update wallpapers"
ON wallpapers FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);
