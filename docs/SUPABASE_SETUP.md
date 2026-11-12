# Supabase setup

## Migrations

The repository history and the existing production database do not share a verified migration baseline. Do **not** run `supabase db push` against production until that baseline is reconciled.

1. `202611050001_foundation.sql` creates a fresh-project schema. Production already contains overlapping objects, so this file must not be executed there.
2. Preserve the supplied CSV inventory, run `supabase/production_schema_followup_export.sql` read-only, export its single result grid, and review `docs/PRODUCTION_SCHEMA_COMPATIBILITY.md`.
3. `202611090001_artist_auth.sql` is a guarded incremental migration mapped to the production column inventory. Test it on a production clone and run `supabase/verify_artist_auth_migration.sql` before approval.

The incremental migration does not delete or rewrite existing records. It must still be backed up, reviewed, and tested in a non-production clone before approval.

## Authentication settings

In Supabase **Authentication → URL Configuration** set:

- Site URL: `https://therealart.in`
- Redirect URLs: `https://therealart.in/auth/callback` and `http://localhost:3000/auth/callback`

Keep email confirmation enabled. Configure a production SMTP provider and update the confirmation/recovery email templates with tRA — The Real Art branding. The application supplies the callback and destination in each request; do not use a wildcard production redirect.

Create a trusted admin identity in Supabase Auth, verify it, then assign its UUID through a trusted SQL session:

```sql
insert into public.user_roles(user_id, role)
values ('<verified-admin-user-uuid>', 'admin');
```

Replace the placeholder manually. Never use email matching, user metadata, or a public sign-up parameter to assign privileged roles.

Production execution, backup/restore, migration-history reconciliation, and smoke-test gates are documented in `docs/PRODUCTION_ROLLOUT_CHECKLIST.md`.

## Application environment

Set these in `.env.local` for development and in Netlify environment variables for production:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<publishable-or-anon-key>
NEXT_PUBLIC_SITE_URL=https://therealart.in
```

The publishable key is expected in the browser/server-rendered application. Never expose the Supabase service-role key. Cloudinary variables are not required until the artwork-upload phase.

## Verification checklist

Register with a synthetic artist address, follow the verification email, and confirm that the existing auth trigger creates one `profiles` row, the RPC creates exactly one `artist` role, and one draft `artist_onboarding_requests` row exists. Verify login, logout, recovery, legal acceptance, mandatory-document submission blocking, expired-link handling, ownership isolation, and rejection of unverified role provisioning. Confirm an artist cannot insert or update `user_roles`, approve onboarding, or access `/admin`.
