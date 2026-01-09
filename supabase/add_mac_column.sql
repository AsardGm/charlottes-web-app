-- Migrace: Přidání MAC sloupce do tabulky messages
-- Datum: 2025-12-28

-- Přidat sloupec mac do tabulky messages
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS mac TEXT;

-- Pro existující zprávy nastavit prázdný MAC (tyto zprávy nebude možné dešifrovat)
-- Můžete je později smazat nebo nechat s označením "[Nelze dešifrovat]"
UPDATE public.messages
SET mac = ''
WHERE mac IS NULL;

-- Nastavit sloupec jako NOT NULL (po naplnění existujících řádků)
ALTER TABLE public.messages
ALTER COLUMN mac SET NOT NULL;
