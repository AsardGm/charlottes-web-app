-- =============================================
-- Charlotte's Web - Seed Data (Optional)
-- =============================================
-- Run this AFTER schema.sql to add test data

-- Note: You need to create users through the app first,
-- then you can promote them to admin with this query:

-- Promote user to admin by email:
-- UPDATE public.profiles
-- SET role = 'admin'
-- WHERE id = (
--     SELECT id FROM auth.users WHERE email = 'your-admin@email.com'
-- );

-- Or promote by username:
-- UPDATE public.profiles
-- SET role = 'admin'
-- WHERE username = 'admin_username';

-- =============================================
-- SAMPLE DATA (uncomment if needed)
-- =============================================

-- Insert sample posts (requires existing user IDs):
-- INSERT INTO public.posts (author_id, content, created_at) VALUES
-- ('user-uuid-here', 'Ahoj vsichni! Vitam vas v nasi komunite kuryru.', now() - interval '2 days'),
-- ('user-uuid-here', 'Dnes skvela smena, 50 zakazek!', now() - interval '1 day'),
-- ('user-uuid-here', 'Nekdo dalsi jede v Praze? Podelte se o tipy!', now());
