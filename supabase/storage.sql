-- =============================================
-- Charlotte's Web - Storage Configuration
-- =============================================
-- Run this AFTER schema.sql

-- Create main public storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verejny',
    'verejny',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- VEREJNY BUCKET POLICIES
-- =============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view verejny files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to verejny" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own verejny files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own verejny files" ON storage.objects;

-- Anyone can view files
CREATE POLICY "Anyone can view verejny files"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'verejny');

-- Authenticated users can upload files
CREATE POLICY "Authenticated users can upload to verejny"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'verejny'
        AND auth.role() = 'authenticated'
    );

-- Users can update their own files
CREATE POLICY "Users can update their own verejny files"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'verejny'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own files
CREATE POLICY "Users can delete their own verejny files"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'verejny'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
