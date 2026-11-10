\set ON_ERROR_STOP on

-- Disposable-local cleanup only. Targets objects and synthetic UUIDs created by the rehearsal fixture.
begin;
drop trigger if exists on_auth_user_created_tra on auth.users;
drop table if exists public.rehearsal_baseline;
drop table if exists public.legal_acceptances cascade;
drop table if exists public.legal_document_versions cascade;
drop table if exists public.legal_documents cascade;
drop table if exists public.artist_onboarding_requests cascade;
drop table if exists public.artist_profiles cascade;
drop table if exists public.user_roles cascade;
drop table if exists public.profiles cascade;
drop function if exists public.accept_artist_legal_version(uuid,text,inet,text);
drop function if exists public.save_artist_onboarding(jsonb);
drop function if exists public.submit_artist_onboarding();
drop function if exists public.tra_prepare_legal_acceptance();
drop function if exists public.register_current_user_as_artist(text);
drop function if exists public.tra_owns_artist(uuid);
drop function if exists public.tra_is_admin();
drop function if exists public.tra_new_user();
drop function if exists public.tra_set_updated_at();
drop type if exists public.artist_status;
drop type if exists public.tra_role;
delete from auth.users where id in (
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000003',
  '10000000-0000-0000-0000-000000000004',
  '10000000-0000-0000-0000-000000000005'
);
commit;
