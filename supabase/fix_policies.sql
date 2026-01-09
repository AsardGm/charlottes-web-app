-- =====================================================
-- Oprava nekonečné rekurze v RLS politikách
-- =====================================================

-- Oprava conversation_participants políčka
DROP POLICY IF EXISTS "Participants can view conversation members" ON public.conversation_participants;
CREATE POLICY "Participants can view conversation members" ON public.conversation_participants
    FOR SELECT USING (
        -- Povolí vidět členy konverzace, pokud je uživatel také členem
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = conversation_participants.conversation_id
            AND cp.user_id = auth.uid()
            AND cp.id != conversation_participants.id  -- Zabránění rekurzi
        )
    );

-- Alternativní jednodušší řešení - povolit vidět všechny členy konverzací, kterých jsem členem
DROP POLICY IF EXISTS "Participants can view conversation members" ON public.conversation_participants;
CREATE POLICY "Participants can view conversation members" ON public.conversation_participants
    FOR SELECT USING (
        -- Uživatel vidí záznam pokud:
        -- 1. Je to jeho vlastní záznam
        user_id = auth.uid()
        OR
        -- 2. Existuje jeho vlastní záznam ve stejné konverzaci
        conversation_id IN (
            SELECT conversation_id
            FROM public.conversation_participants
            WHERE user_id = auth.uid()
        )
    );
