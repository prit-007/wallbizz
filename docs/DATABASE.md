# Database Schema

## Tables

### wallpapers (Cache Table)

Populated by the Golang backend from Wallhaven. Flutter reads from this for all browsing.

```sql
CREATE TABLE wallpapers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallhaven_id VARCHAR(50) UNIQUE NOT NULL,
    url_full TEXT NOT NULL,
    url_thumb TEXT NOT NULL,
    resolution VARCHAR(20) NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    file_size BIGINT,
    primary_color VARCHAR(10),
    category VARCHAR(20) NOT NULL DEFAULT 'general',
    source_query VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

### wishlists (User Data)

Managed by Flutter client. RLS ensures users can only access their own data.

```sql
CREATE TABLE wishlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    wallpaper_id UUID REFERENCES wallpapers(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, wallpaper_id)
);
```

### moodboards (Named Collections)

Authenticated user creates named moodboard collections.

```sql
CREATE TABLE moodboards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

### moodboard_items (Wallpaper References)

Moodboard contents — wallpaper references within a moodboard.

```sql
CREATE TABLE moodboard_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    moodboard_id UUID REFERENCES moodboards(id) ON DELETE CASCADE NOT NULL,
    wallpaper_id UUID REFERENCES wallpapers(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(moodboard_id, wallpaper_id)
);
```

## Row Level Security

| Table | Policy | Who |
|-------|--------|-----|
| wallpapers | Public read (SELECT) | Everyone (via Anon Key) |
| wallpapers | No client write | Backend uses Service Key (bypasses RLS) |
| wishlists | SELECT WHERE auth.uid() = user_id | Users see own data only |
| wishlists | INSERT WHERE auth.uid() = user_id | Users add to own wishlist |
| wishlists | DELETE WHERE auth.uid() = user_id | Users remove from own wishlist |
| moodboards | All operations WHERE auth.uid() = user_id | Users manage own moodboards |
| moodboard_items | All operations via moodboard user_id check | Users manage own moodboard items |

## Performance Indexes

```sql
CREATE INDEX idx_wallpapers_created_at ON wallpapers(created_at DESC);     -- Home feed
CREATE INDEX idx_wallpapers_category ON wallpapers(source_query);          -- Category filter
CREATE INDEX idx_wishlists_user_id ON wishlists(user_id);                  -- User wishlist
CREATE INDEX idx_wishlists_wallpaper_id ON wishlists(wallpaper_id);        -- JOIN speedup
CREATE INDEX idx_moodboards_user_id ON moodboards(user_id);               -- User moodboards
CREATE INDEX idx_moodboard_items_moodboard ON moodboard_items(moodboard_id); -- Moodboard content
```

## Common Queries

```sql
-- Home feed (latest 24 trending)
SELECT * FROM wallpapers
WHERE source_query = 'trending'
ORDER BY created_at DESC LIMIT 24;

-- Category filter (page 2)
SELECT * FROM wallpapers
WHERE source_query = 'anime'
ORDER BY created_at DESC
LIMIT 24 OFFSET 24;

-- User wishlist
SELECT w.* FROM wallpapers w
JOIN wishlists wl ON wl.wallpaper_id = w.id
WHERE wl.user_id = 'user-uuid'
ORDER BY wl.created_at DESC;

-- Upsert (backend)
INSERT INTO wallpapers (wallhaven_id, url_full, url_thumb, resolution, width, height, file_size, primary_color, category, source_query)
VALUES ('94x38z', '...', '...', '3840x2160', 3840, 2160, 4200000, '#000000', 'anime', 'anime')
ON CONFLICT (wallhaven_id) DO UPDATE SET
    url_full = EXCLUDED.url_full, url_thumb = EXCLUDED.url_thumb,
    resolution = EXCLUDED.resolution, width = EXCLUDED.width,
    height = EXCLUDED.height, file_size = EXCLUDED.file_size,
    primary_color = EXCLUDED.primary_color, category = EXCLUDED.category,
    source_query = EXCLUDED.source_query;
```

## Column Rationale

| Column | Type | Why |
|--------|------|-----|
| `id` | UUID | Supabase standard, no sequential data leak |
| `wallhaven_id` | VARCHAR(50) | Wallhaven IDs are alphanumeric strings |
| `width`/`height` | INTEGER | Exact pixels, needed for aspect ratio calculation |
| `file_size` | BIGINT | Images can theoretically exceed 2GB |
| `source_query` | VARCHAR(100) | Category labels; enum would require migration for changes |
