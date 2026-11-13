-- Read-only verification after separately approved application.
select enumlabel from pg_enum join pg_type on pg_type.oid=enumtypid where typname='tra_role' order by enumsortorder;
select role,count(*) permissions from public.role_permissions group by role order by role;
select account_status,count(*) from public.profiles group by account_status;
select tablename,rowsecurity from pg_tables where schemaname='public' and tablename in ('role_permissions','user_permission_overrides','account_invitations');
select proname,prosecdef from pg_proc join pg_namespace n on n.oid=pronamespace where n.nspname='public' and proname like 'tra_%' order by proname;
select count(*) filter(where revoked_at is not null and status<>'ended') invalid_revocations from public.artist_representations;

