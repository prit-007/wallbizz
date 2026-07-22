-- ============================================================
-- 004_moodboards.sql — Moodboard (collection folders) tables
-- ============================================================

CREATE TABLE moodboards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE moodboard_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  moodboard_id UUID REFERENCES moodboards(id) ON DELETE CASCADE NOT NULL,
  wallpaper_id UUID REFERENCES wallpapers(id) ON DELETE CASCADE NOT NULL,
  added_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(moodboard_id, wallpaper_id)
);

-- RLS
ALTER TABLE moodboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE moodboard_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own moodboards"
ON moodboards FOR ALL
USING (auth.uid() = user_id);

CREATE POLICY "Users manage their moodboard items"
ON moodboard_items FOR ALL
USING (
  moodboard_id IN (
    SELECT id FROM moodboards WHERE user_id = auth.uid()
  )
);

-- Indexes
CREATE INDEX idx_moodboards_user ON moodboards(user_id);
CREATE INDEX idx_moodboard_items_board ON moodboard_items(moodboard_id);
