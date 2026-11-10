-- READ ONLY production rollout preflight. Run in Supabase SQL Editor before approval.
-- Do not continue unless every issue_count is zero and server_version is approved.

select
  current_setting('server_version') as server_version,
  current_setting('server_version_num')::integer as server_version_num,
  current_database() as database_name,
  current_user as executed_by,
  clock_timestamp() as observed_at_utc;

select version
from supabase_migrations.schema_migrations
where version in ('202611050001','202611090001')
order by version;

select 'duplicate_user_roles' as check_name,count(*) as issue_count from (
  select user_id,role from public.user_roles group by user_id,role having count(*)>1
) x
union all
select 'duplicate_artist_profile_user',count(*) from (
  select user_id from public.artist_profiles group by user_id having count(*)>1
) x
union all
select 'duplicate_artist_onboarding',count(*) from (
  select artist_id from public.artist_onboarding_requests group by artist_id having count(*)>1
) x
union all
select 'duplicate_legal_acceptance',count(*) from (
  select user_id,version_id from public.legal_acceptances group by user_id,version_id having count(*)>1
) x
union all
select 'profile_without_auth_user',count(*) from public.profiles p
left join auth.users u on u.id=p.id where u.id is null
union all
select 'role_without_auth_user',count(*) from public.user_roles r
left join auth.users u on u.id=r.user_id where u.id is null
union all
select 'artist_profile_without_auth_user',count(*) from public.artist_profiles p
left join auth.users u on u.id=p.user_id where u.id is null
union all
select 'onboarding_without_profile',count(*) from public.artist_onboarding_requests o
left join public.artist_profiles p on p.id=o.artist_id where p.id is null
union all
select 'version_without_document',count(*) from public.legal_document_versions v
left join public.legal_documents d on d.id=v.document_id where d.id is null
union all
select 'acceptance_without_user',count(*) from public.legal_acceptances a
left join auth.users u on u.id=a.user_id where u.id is null
union all
select 'acceptance_without_version',count(*) from public.legal_acceptances a
left join public.legal_document_versions v on v.id=a.version_id where v.id is null
union all
select 'missing_required_policy',count(*) from (values
  ('profiles','profile_admin_insert'),('profiles','profile_read'),('profiles','profile_update'),
  ('user_roles','admin_all'),('user_roles','role_self_read'),
  ('artist_profiles','artist_admin_all'),('artist_profiles','artist_public_read'),
  ('artist_profiles','artist_self_insert'),('artist_profiles','artist_self_update'),
  ('artist_onboarding_requests','onboarding_admin'),('artist_onboarding_requests','onboarding_read'),
  ('legal_documents','admin_all'),('legal_documents','legal_artist_read'),('legal_documents','legal_public_read'),
  ('legal_document_versions','admin_all'),('legal_document_versions','legal_versions_artist'),('legal_document_versions','legal_versions_read'),
  ('legal_acceptances','legal_acceptance_admin'),('legal_acceptances','legal_acceptance_insert'),('legal_acceptances','legal_acceptance_read')
) expected(table_name,policy_name) where not exists(
  select 1 from pg_policies p where p.schemaname='public'
    and p.tablename=expected.table_name and p.policyname=expected.policy_name
)
union all
select 'target_function_conflict',count(*) from (values
  ('public.accept_artist_legal_version(uuid,text,inet,text)'),
  ('public.save_artist_onboarding(jsonb)'),
  ('public.submit_artist_onboarding()'),
  ('public.tra_prepare_legal_acceptance()')
) target(signature) where to_regprocedure(target.signature) is not null
union all
select 'target_trigger_conflict',count(*) from pg_trigger
where tgname='tra_legal_acceptance_immutable_snapshot' and not tgisinternal
union all
select 'target_index_name_conflict',count(*) from (values
  ('public.tra_user_roles_user_role_uq'),
  ('public.tra_artist_onboarding_artist_uq'),
  ('public.tra_legal_acceptance_user_version_uq')
) target(name) where to_regclass(target.name) is not null;

select table_name,row_count from (
  select 'profiles'::text as table_name,count(*)::bigint as row_count from public.profiles
  union all select 'user_roles',count(*) from public.user_roles
  union all select 'artist_profiles',count(*) from public.artist_profiles
  union all select 'artist_onboarding_requests',count(*) from public.artist_onboarding_requests
  union all select 'legal_documents',count(*) from public.legal_documents
  union all select 'legal_document_versions',count(*) from public.legal_document_versions
  union all select 'legal_acceptances',count(*) from public.legal_acceptances
) snapshot order by table_name;

select pid,usename,state,xact_start,query_start,wait_event_type,wait_event,
       left(query,200) as query_preview
from pg_stat_activity
where datname=current_database() and pid<>pg_backend_pid()
  and (xact_start is not null or state<>'idle')
order by coalesce(xact_start,query_start);
