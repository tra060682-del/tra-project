-- Development-only test cleanup. Apply only to tra-development, never production.
create or replace function public.tra_cleanup_development_synthetic_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path=public,auth,pg_temp
as $$
declare
  target_email text;
begin
  if not exists(
    select 1 from public.platform_settings
    where key='development_environment'
      and value @> '{"synthetic":true,"production_data":false}'::jsonb
  ) then
    raise exception 'DEVELOPMENT_ENVIRONMENT_MARKER_REQUIRED';
  end if;

  select email into target_email from auth.users where id=p_user_id;
  if target_email is null or target_email !~ '^ci\..+@example\.test$' then
    raise exception 'SYNTHETIC_USER_REQUIRED';
  end if;

  update public.artist_onboarding_requests
     set reviewed_by=null,reviewed_at=null where reviewed_by=p_user_id;
  update public.artist_profiles
     set reviewed_by=null,reviewed_at=null where reviewed_by=p_user_id;

  lock table public.legal_acceptances in access exclusive mode;
  execute 'alter table public.legal_acceptances disable trigger tra_legal_acceptance_immutable_snapshot';
  begin
    delete from public.legal_acceptances where user_id=p_user_id;
    execute 'alter table public.legal_acceptances enable trigger tra_legal_acceptance_immutable_snapshot';
  exception when others then
    execute 'alter table public.legal_acceptances enable trigger tra_legal_acceptance_immutable_snapshot';
    raise;
  end;

  delete from public.artist_onboarding_requests o using public.artist_profiles p
   where o.artist_id=p.id and p.user_id=p_user_id;
  delete from public.artist_profiles where user_id=p_user_id;
  delete from public.user_roles where user_id=p_user_id;
  delete from public.profiles where id=p_user_id;
end
$$;

revoke all on function public.tra_cleanup_development_synthetic_user(uuid) from public,anon,authenticated;
grant execute on function public.tra_cleanup_development_synthetic_user(uuid) to service_role;
