-- ============================================
-- Storage Policies pro Strain bucket
-- Spusťte v Supabase SQL Editoru
-- ============================================

-- 1. Policy: Authenticated users mohou nahrávat do své složky scans/{user_id}/*
CREATE POLICY "Users can upload scan images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'Strain' AND
  (storage.foldername(name))[1] = 'scans'
);

-- 2. Policy: Authenticated users mohou číst vlastní skeny
CREATE POLICY "Users can read own scans"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'Strain'
);

-- 3. Policy: Users mohou mazat vlastní soubory
CREATE POLICY "Users can delete own scans"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'Strain' AND
  (storage.foldername(name))[1] = 'scans'
);

-- 4. Policy: Veřejné čtení (aby se obrázky zobrazovaly všem)
CREATE POLICY "Public can view scan images"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'Strain'
);

-- Hotovo! Scanner by měl nyní fungovat.
