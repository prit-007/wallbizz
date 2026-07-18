-- ============================================================
-- 002_rls.sql — Row Level Security policies
-- ============================================================

-- Enable RLS on both tables
ALTER TABLE wallpapers ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------
-- WALLPAPERS: Public read, backend-only write
-- ----------------------------------------------------------

-- Anyone (including anonymous users) can read wallpapers.
CREATE POLICY "Wallpapers are publicly viewable"
ON wallpapers FOR SELECT
USING (true);

-- No INSERT/UPDATE/DELETE policies for the client.
-- The Golang backend uses the Service Role Key, which bypasses RLS.

-- ----------------------------------------------------------
-- WISHLISTS: User-scoped read/insert/delete
-- ----------------------------------------------------------

-- Users can only see their own wishlist items.
CREATE POLICY "Users can view their own wishlists"
ON wishlists FOR SELECT
USING (auth.uid() = user_id);

-- Users can only insert wishlists for themselves.
CREATE POLICY "Users can insert their own wishlists"
ON wishlists FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own wishlist items.
CREATE POLICY "Users can delete their own wishlists"
ON wishlists FOR DELETE
USING (auth.uid() = user_id);
