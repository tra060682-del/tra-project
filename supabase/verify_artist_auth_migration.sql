-- READ ONLY post-migration verification. Every issue_count should be zero.

select 'missing_rpc' as check_name,count(*) as issue_count
from (values
  ('public.register_current_user_as_artist(text)'),
  ('public.accept_artist_legal_version(uuid,text,inet,text)'),
  ('public.save_artist_onboarding(jsonb)'),
  ('public.submit_artist_onboarding()'),
  ('public.tra_prepare_legal_acceptance()')
) expected(signature) where to_regprocedure(expected.signature) is null
union all
select 'missing_trigger',case when exists(
  select 1 from pg_trigger where tgname='tra_legal_acceptance_immutable_snapshot' and not tgisinternal
) then 0 else 1 end
union all
select 'missing_acceptance_evidence_column',count(*) from (values
  ('acceptance_statement'),('accepted_content_sha256')
) expected(column_name) where not exists(
  select 1 from information_schema.columns c where c.table_schema='public'
    and c.table_name='legal_acceptances' and c.column_name=expected.column_name
)
union all
select 'rls_disabled',count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) and not c.relrowsecurity
union all
select 'missing_preexisting_policy',count(*) from (values
  ('legal_acceptances','legal_acceptance_admin'),
  ('legal_acceptances','legal_acceptance_insert'),
  ('legal_acceptances','legal_acceptance_read'),
  ('profiles','profile_admin_insert'),
  ('profiles','profile_read'),
  ('profiles','profile_update'),
  ('user_roles','admin_all'),
  ('user_roles','role_self_read'),
  ('artist_profiles','artist_admin_all'),
  ('artist_profiles','artist_public_read'),
  ('artist_profiles','artist_self_insert'),
  ('artist_profiles','artist_self_update'),
  ('artist_onboarding_requests','onboarding_admin'),
  ('artist_onboarding_requests','onboarding_read'),
  ('legal_documents','admin_all'),
  ('legal_documents','legal_artist_read'),
  ('legal_documents','legal_public_read'),
  ('legal_document_versions','admin_all'),
  ('legal_document_versions','legal_versions_artist'),
  ('legal_document_versions','legal_versions_read')
) expected(table_name,policy_name) where not exists(
  select 1 from pg_policies p where p.schemaname='public'
    and p.tablename=expected.table_name and p.policyname=expected.policy_name
)
union all
select 'duplicate_user_roles',count(*) from (
  select user_id,role from public.user_roles group by user_id,role having count(*)>1
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
select 'empty_acceptance_snapshot',count(*) from public.legal_acceptances
where accepted_text_snapshot is null or accepted_text_snapshot='';

select p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
       p.prosecdef as security_definer,p.proconfig
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in (
  'register_current_user_as_artist','accept_artist_legal_version',
  'save_artist_onboarding','submit_artist_onboarding','tra_prepare_legal_acceptance'
) order by p.proname;

select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public' and tablename in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by tablename,policyname;

select event_object_table,trigger_name,event_manipulation,action_timing,action_statement
from information_schema.triggers where trigger_schema='public' and event_object_table in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by event_object_table,trigger_name,event_manipulation;

select 'artist_role_without_onboarding' as check_name,count(*) as issue_count
from public.user_roles r
left join public.artist_profiles ap on ap.user_id=r.user_id
left join public.artist_onboarding_requests o on o.artist_id=ap.id
where r.role::text='artist' and o.id is null
union all
select 'onboarding_without_profile',count(*) from public.artist_onboarding_requests o
left join public.artist_profiles p on p.id=o.artist_id where p.id is null
union all
select 'duplicate_artist_profile_user',count(*) from (
  select user_id from public.artist_profiles group by user_id having count(*)>1
) x
union all
select 'artist_profile_without_auth_user',count(*) from public.artist_profiles p
left join auth.users u on u.id=p.user_id where u.id is null;
