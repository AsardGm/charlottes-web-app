-- =====================================================
-- SUPABASE DATABASE SETUP
-- Komunita App - Social Community Platform
-- =====================================================

-- Enable UUID extension (should be enabled by default)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- PROFILES TABLE
-- Extends auth.users with additional profile information
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    email TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin')),
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- POSTS TABLE
-- Main content table for community posts
-- =====================================================
CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- COMMENTS TABLE
-- Comments on posts
-- =====================================================
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- REACTIONS TABLE
-- Emoji reactions on posts (like, love, laugh, etc.)
-- =====================================================
CREATE TABLE IF NOT EXISTS reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('like', 'love', 'laugh', 'wow', 'sad', 'angry')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- =====================================================
-- INDEXES
-- Improve query performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_author ON comments(author_id);
CREATE INDEX IF NOT EXISTS idx_reactions_post ON reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON reactions(user_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES POLICIES
-- =====================================================

-- Anyone can view profiles
CREATE POLICY "Profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Admins can update any profile
CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =====================================================
-- POSTS POLICIES
-- =====================================================

-- Anyone authenticated can view posts
CREATE POLICY "Posts are viewable by authenticated users"
ON posts FOR SELECT
USING (auth.role() = 'authenticated');

-- Authenticated users can create posts (if not blocked)
CREATE POLICY "Authenticated users can create posts"
ON posts FOR INSERT
WITH CHECK (
    auth.uid() = author_id
    AND NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_blocked = true
    )
);

-- Users can update their own posts
CREATE POLICY "Users can update own posts"
ON posts FOR UPDATE
USING (auth.uid() = author_id);

-- Users can delete their own posts
CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE
USING (auth.uid() = author_id);

-- Admins can delete any post
CREATE POLICY "Admins can delete any post"
ON posts FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =====================================================
-- COMMENTS POLICIES
-- =====================================================

-- Anyone authenticated can view comments
CREATE POLICY "Comments are viewable by authenticated users"
ON comments FOR SELECT
USING (auth.role() = 'authenticated');

-- Authenticated users can create comments (if not blocked)
CREATE POLICY "Authenticated users can create comments"
ON comments FOR INSERT
WITH CHECK (
    auth.uid() = author_id
    AND NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_blocked = true
    )
);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE
USING (auth.uid() = author_id);

-- Admins can delete any comment
CREATE POLICY "Admins can delete any comment"
ON comments FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =====================================================
-- REACTIONS POLICIES
-- =====================================================

-- Anyone authenticated can view reactions
CREATE POLICY "Reactions are viewable by authenticated users"
ON reactions FOR SELECT
USING (auth.role() = 'authenticated');

-- Authenticated users can create reactions (if not blocked)
CREATE POLICY "Authenticated users can create reactions"
ON reactions FOR INSERT
WITH CHECK (
    auth.uid() = user_id
    AND NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_blocked = true
    )
);

-- Users can delete their own reactions
CREATE POLICY "Users can delete own reactions"
ON reactions FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- STORAGE BUCKET
-- Run this in Supabase Dashboard > Storage
-- =====================================================
-- Create a bucket named 'images' with public access
-- Or run: INSERT INTO storage.buckets (id, name, public) VALUES ('images', 'images', true);

-- Storage policies (run in SQL editor)
-- CREATE POLICY "Authenticated users can upload images"
-- ON storage.objects FOR INSERT
-- WITH CHECK (bucket_id = 'images' AND auth.role() = 'authenticated');

-- CREATE POLICY "Anyone can view images"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'images');

-- CREATE POLICY "Users can delete own images"
-- ON storage.objects FOR DELETE
-- USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =====================================================
-- FUNCTION: Auto-create profile on signup
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, email, role, is_blocked, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        NEW.email,
        'member',
        false,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- OPTIONAL: Create first admin user
-- Replace 'your-user-id' with actual UUID after registration
-- =====================================================
-- UPDATE profiles SET role = 'admin' WHERE id = 'your-user-id';
