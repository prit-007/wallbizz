-- ============================================================
-- 001_schema.sql — Table definitions for the wallpaper app
-- ============================================================

-- 1. Wallpapers Table (The Cache)
-- Populated by the Golang backend from Wallhaven API.
-- Flutter reads from this table for all wallpaper browsing.
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

-- 2. Wishlists Table (Many-to-Many mapping)
-- Managed by Flutter client via Supabase Anon Key (RLS enforced).
CREATE TABLE wishlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    wallpaper_id UUID REFERENCES wallpapers(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, wallpaper_id)
);
