# Supabase setup

1. Create the intended India pilot Supabase project and apply `supabase/migrations/202611050001_foundation.sql` using a trusted migration session. Supabase CLI can apply migrations with `supabase db push` after linking the correct project. No database credentials are supplied in this source package.
2. Set the project URL and publishable key in `.env.local`; keep production values in Netlify environment settings. Configure auth site/redirect URLs and verified email requirements.
3. Create a trusted admin identity in Supabase Auth, then assign its UUID `super_admin` through a trusted SQL session: `insert into public.user_roles(user_id, role) values ('<verified-admin-user-uuid>', 'super_admin');` Replace the placeholder manually. Never use a public sign-up parameter to assign roles.
4. Create only synthetic data while testing. Publish an active auction terms version, approve an artist, publish a work and schedule a test auction through trusted test fixtures. No production seed or automatic admin creation is included.
5. Complete SQL integration/RLS/concurrency tests and implement secure operational management before opening bidding. Do not use the current foundation as a live bidding launch.
