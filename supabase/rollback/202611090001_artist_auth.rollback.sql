-- Conservative rollback for 202611090001_artist_auth.sql.
-- Removes only uniquely named behaviour added by the migration.

begin;

drop trigger if exists tra_legal_acceptance_immutable_snapshot on public.legal_acceptances;
drop function if exists public.tra_prepare_legal_acceptance();
drop function if exists public.accept_artist_legal_version(uuid,text,inet,text);
drop function if exists public.save_artist_onboarding(jsonb);
drop function if exists public.submit_artist_onboarding();

create or replace function public.register_current_user_as_artist(p_display_name text default null)
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare
  current_user_id uuid:=auth.uid();
  confirmed_at timestamptz;
  metadata_name text;
  profile_id uuid;
begin
  if current_user_id is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  select email_confirmed_at,nullif(btrim(raw_user_meta_data->>'display_name'),'')
    into confirmed_at,metadata_name from auth.users where id=current_user_id;
  if confirmed_at is null then raise exception 'VERIFIED_EMAIL_REQUIRED'; end if;
  metadata_name:=coalesce(nullif(btrim(p_display_name),''),metadata_name);
  if metadata_name is null or char_length(metadata_name) not between 2 and 120 then
    raise exception 'VALID_DISPLAY_NAME_REQUIRED';
  end if;
  insert into public.user_roles(user_id,role)
    values(current_user_id,'artist') on conflict do nothing;
  insert into public.artist_profiles(user_id,display_name)
    values(current_user_id,metadata_name)
    on conflict(user_id) do update set display_name=public.artist_profiles.display_name
    returning id into profile_id;
  return profile_id;
end
$$;

drop index if exists public.tra_user_roles_user_role_uq;
drop index if exists public.tra_artist_onboarding_artist_uq;
drop index if exists public.tra_legal_acceptance_user_version_uq;

commit;

-- Intentionally retained:
--   legal_acceptances.acceptance_statement
--   legal_acceptances.accepted_content_sha256
--   table grants and RLS enabled/forced flags
-- These can contain or govern post-migration production data. Restore grants and
-- RLS flags only from the captured pre-migration inventory. Drop the two columns
-- only after a backup proves they contain no required evidence.
