-- READ ONLY. Run before approving 202611090001_artist_auth.sql.
-- Export every grid. This collects facts absent from the two supplied CSVs.

select n.nspname as schema_name,t.relname as table_name,c.conname,c.contype,
       c.convalidated,pg_get_constraintdef(c.oid,true) as definition
from pg_constraint c join pg_class t on t.oid=c.conrelid
join pg_namespace n on n.oid=t.relnamespace
where n.nspname='public' and t.relname in (
  'profiles','user_roles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by t.relname,c.contype,c.conname;

select schemaname,tablename,indexname,indexdef
from pg_indexes where schemaname='public' and tablename in (
  'profiles','user_roles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by tablename,indexname;

select c.relname as table_name,c.relrowsecurity as rls_enabled,c.relforcerowsecurity as rls_forced,
       pg_get_userbyid(c.relowner) as owner
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r' and c.relname in (
  'profiles','user_roles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by c.relname;

select event_object_schema,event_object_table,trigger_name,event_manipulation,
       action_timing,action_condition,action_statement
from information_schema.triggers
where (event_object_schema='public' and event_object_table in (
  'profiles','user_roles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
)) or (event_object_schema='auth' and event_object_table='users')
order by event_object_schema,event_object_table,trigger_name,event_manipulation;

select n.nspname as schema_name,p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,p.proleakproof as leakproof,
       pg_get_userbyid(p.proowner) as owner,p.proconfig,
       pg_get_functiondef(p.oid) as definition
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname in ('public','auth') and (
  p.proname='tra_is_admin' or p.proname ilike '%profile%' or
  p.proname ilike '%artist%' or p.proname ilike '%legal%'
) order by n.nspname,p.proname,arguments;

select n.nspname as schema_name,t.typname as enum_name,e.enumsortorder,e.enumlabel
from pg_enum e join pg_type t on t.oid=e.enumtypid
join pg_namespace n on n.oid=t.typnamespace
where n.nspname='public' and t.typname in (
  select c.udt_name from information_schema.columns c
  where c.table_schema='public' and (
    (c.table_name='user_roles' and c.column_name='role') or
    (c.table_name='artist_onboarding_requests' and c.column_name='status')
  )
) order by t.typname,e.enumsortorder;

select table_name,grantee,privilege_type,is_grantable
from information_schema.role_table_grants
where table_schema='public' and table_name in (
  'profiles','user_roles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by table_name,grantee,privilege_type;

select table_name,column_name,grantee,privilege_type,is_grantable
from information_schema.role_column_grants
where table_schema='public' and table_name in (
  'profiles','user_roles','artist_onboarding_requests','legal_documents',
  'legal_document_versions','legal_acceptances'
) order by table_name,column_name,grantee,privilege_type;

select n.nspname as schema_name,p.proname,pg_get_function_identity_arguments(p.oid) arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in (
  'register_current_user_as_artist','accept_artist_legal_version',
  'save_artist_onboarding','submit_artist_onboarding','tra_prepare_legal_acceptance'
);

-- Count-only checks; no personal or legal content is returned.
select 'duplicate_user_roles' as check_name,count(*) as issue_count from (
  select user_id,role from public.user_roles group by user_id,role having count(*)>1
) x union all
select 'duplicate_artist_onboarding',count(*) from (
  select artist_id from public.artist_onboarding_requests group by artist_id having count(*)>1
) x union all
select 'duplicate_legal_acceptance',count(*) from (
  select user_id,version_id from public.legal_acceptances group by user_id,version_id having count(*)>1
) x union all
select 'profile_without_auth_user',count(*) from public.profiles p
  left join auth.users u on u.id=p.id where u.id is null
union all
select 'role_without_auth_user',count(*) from public.user_roles r
  left join auth.users u on u.id=r.user_id where u.id is null
union all
select 'onboarding_without_profile',count(*) from public.artist_onboarding_requests o
  left join public.profiles p on p.id=o.artist_id where p.id is null
union all
select 'version_without_document',count(*) from public.legal_document_versions v
  left join public.legal_documents d on d.id=v.document_id where d.id is null
union all
select 'acceptance_without_user',count(*) from public.legal_acceptances a
  left join auth.users u on u.id=a.user_id where u.id is null
union all
select 'acceptance_without_version',count(*) from public.legal_acceptances a
  left join public.legal_document_versions v on v.id=a.version_id where v.id is null;
