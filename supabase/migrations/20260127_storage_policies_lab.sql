-- ============================================
-- Lab Feature - Storage bucket a politiky
-- ============================================

-- 1. Vytvor bucket pro Lab soubory
INSERT INTO storage.buckets (id, name, public)
VALUES ('lab', 'lab', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage politiky pro Lab bucket
DROP POLICY IF EXISTS "Users can upload lab files" ON storage.objects;
CREATE POLICY "Users can upload lab files" ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'lab'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "Users can view lab files" ON storage.objects;
CREATE POLICY "Users can view lab files" ON storage.objects
FOR SELECT
USING (bucket_id = 'lab');

DROP POLICY IF EXISTS "Users can delete own lab files" ON storage.objects;
CREATE POLICY "Users can delete own lab files" ON storage.objects
FOR DELETE
USING (
  bucket_id = 'lab'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Hotovo!
