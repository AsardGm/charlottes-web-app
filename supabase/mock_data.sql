-- =============================================
-- Charlotte's Web - Mock Data
-- =============================================
-- Tento skript vytvori testovaci uzivatele a data

-- =============================================
-- MOCK DATA
-- =============================================

DO $$
DECLARE
    user1_id UUID := 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
    user2_id UUID := 'b2c3d4e5-f6a7-8901-bcde-f12345678901';
    user3_id UUID := 'c3d4e5f6-a7b8-9012-cdef-123456789012';
    post1_id UUID;
    post2_id UUID;
    post3_id UUID;
    post4_id UUID;
    post5_id UUID;
BEGIN
    -- Vytvor testovaci uzivatele (preskoc pokud existuji)
    INSERT INTO profiles (id, username, avatar_url, role, is_blocked, created_at)
    VALUES
        (user1_id, 'petr_kuryr', NULL, 'admin', false, now() - interval '30 days'),
        (user2_id, 'jana_rider', NULL, 'member', false, now() - interval '20 days'),
        (user3_id, 'martin_speed', NULL, 'member', false, now() - interval '10 days')
    ON CONFLICT (id) DO NOTHING;

    -- Vytvor prispevky od ruznych uzivatelu
    INSERT INTO posts (id, author_id, content, created_at)
    VALUES (
        uuid_generate_v4(),
        user1_id,
        'Ahoj vsichni! Vitam vas v nasi komunite kuryru. Jsem rad, ze jste tady! Jak se vam dari na cestach? 🚴‍♂️',
        now() - interval '5 days'
    ) RETURNING id INTO post1_id;

    INSERT INTO posts (id, author_id, content, created_at)
    VALUES (
        uuid_generate_v4(),
        user2_id,
        'Dnes skvela smena! 47 zakazek za 8 hodin, rekord tohoto mesice. Kdo da vic? 💪',
        now() - interval '3 days'
    ) RETURNING id INTO post2_id;

    INSERT INTO posts (id, author_id, content, created_at)
    VALUES (
        uuid_generate_v4(),
        user1_id,
        'Tip pro novacky: Vzdycky si nechte nabity powerbanku. Nic neni horsi nez kdyz vam dojde baterka uprostred smeny! 🔋',
        now() - interval '2 days'
    ) RETURNING id INTO post3_id;

    INSERT INTO posts (id, author_id, content, created_at)
    VALUES (
        uuid_generate_v4(),
        user3_id,
        'Hledame dalsi kurery do naseho tymu v Praze! Kdyz mate zajem, napiste mi do DM. Skvele podminky a super parta. 📦',
        now() - interval '1 day'
    ) RETURNING id INTO post4_id;

    INSERT INTO posts (id, author_id, content, created_at)
    VALUES (
        uuid_generate_v4(),
        user2_id,
        'Vikendova smena za mnou. Pocasi bylo super, lidi prijemni. Tak zase priste! Uzijte si nedeli 🌞',
        now() - interval '6 hours'
    ) RETURNING id INTO post5_id;

    -- Pridej komentare od ruznych uzivatelu
    INSERT INTO comments (post_id, author_id, content, created_at)
    VALUES
    (post1_id, user2_id, 'Supr iniciativa! Dekuji za vytvoreni teto komunity.', now() - interval '4 days'),
    (post2_id, user1_id, 'To je hustej rekord! Gratuluju 👏', now() - interval '2 days'),
    (post2_id, user3_id, 'Ja mel vcera 52, ale trvalo to 10 hodin 😅', now() - interval '2 days'),
    (post3_id, user2_id, 'Diky za tip! Mam uz tri powerbanky v batohu 😂', now() - interval '1 day'),
    (post4_id, user1_id, 'Mate nejake pozadavky na kolo?', now() - interval '12 hours'),
    (post5_id, user3_id, 'Hezkou nedeli! 🙌', now() - interval '3 hours');

    -- Pridej reakce od ruznych uzivatelu
    INSERT INTO reactions (post_id, user_id, type, created_at)
    VALUES
    (post1_id, user2_id, 'love', now() - interval '4 days'),
    (post1_id, user3_id, 'like', now() - interval '4 days'),
    (post2_id, user1_id, 'wow', now() - interval '2 days'),
    (post2_id, user3_id, 'like', now() - interval '2 days'),
    (post3_id, user2_id, 'like', now() - interval '1 day'),
    (post4_id, user1_id, 'like', now() - interval '10 hours'),
    (post4_id, user2_id, 'love', now() - interval '10 hours'),
    (post5_id, user1_id, 'love', now() - interval '2 hours');

    RAISE NOTICE 'Mock data uspesne vytvorena!';
END $$;

-- =============================================
-- OVERENI
-- =============================================
-- SELECT COUNT(*) as posts FROM posts;
-- SELECT COUNT(*) as comments FROM comments;
-- SELECT COUNT(*) as reactions FROM reactions;
