-- =============================================
-- Migration: Add missing columns to profiles table
-- Run this in Supabase SQL Editor
-- =============================================

-- Add bio column
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS bio TEXT;

-- Add website column
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS website TEXT;

-- Add location column
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS location TEXT;

-- Add follower_count column (with default 0)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS follower_count INTEGER NOT NULL DEFAULT 0;

-- Add following_count column (with default 0)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS following_count INTEGER NOT NULL DEFAULT 0;

-- Add post_count column (with default 0)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS post_count INTEGER NOT NULL DEFAULT 0;

-- =============================================
-- Optional: Update post_count for existing users
-- =============================================
UPDATE public.profiles p
SET post_count = (
    SELECT COUNT(*) FROM public.posts
    WHERE author_id = p.id
);

-- =============================================
-- Trigger to auto-update post_count
-- =============================================
CREATE OR REPLACE FUNCTION public.update_user_post_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.profiles
        SET post_count = post_count + 1
        WHERE id = NEW.author_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.profiles
        SET post_count = GREATEST(0, post_count - 1)
        WHERE id = OLD.author_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_post_count_change ON public.posts;

-- Create trigger
CREATE TRIGGER on_post_count_change
    AFTER INSERT OR DELETE ON public.posts
    FOR EACH ROW EXECUTE FUNCTION public.update_user_post_count();

-- =============================================
-- Verify columns exist
-- =============================================
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'profiles'
-- ORDER BY ordinal_position;
