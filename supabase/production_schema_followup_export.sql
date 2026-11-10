-- READ ONLY, SINGLE RESULT SET.
-- Export this one grid as CSV so no preceding result grids are lost.

with inventory(section,object_name,detail) as (
  select 'constraint',n.nspname||'.'||t.relname||'.'||c.conname,
         jsonb_build_object('type',c.contype,'validated',c.convalidated,
                            'definition',pg_get_constraintdef(c.oid,true))
  from pg_constraint c join pg_class t on t.oid=c.conrelid
  join pg_namespace n on n.oid=t.relnamespace
  where n.nspname='public' and t.relname in (
    'profiles','user_roles','artist_onboarding_requests','legal_documents',
    'legal_document_versions','legal_acceptances'
  )
  union all
  select 'index',schemaname||'.'||indexname,
         jsonb_build_object('table',tablename,'definition',indexdef)
  from pg_indexes where schemaname='public' and tablename in (
    'profiles','user_roles','artist_onboarding_requests','legal_documents',
    'legal_document_versions','legal_acceptances'
  )
  union all
  select 'rls',n.nspname||'.'||c.relname,
         jsonb_build_object('enabled',c.relrowsecurity,'forced',c.relforcerowsecurity,
                            'owner',pg_get_userbyid(c.relowner))
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind='r' and c.relname in (
    'profiles','user_roles','artist_onboarding_requests','legal_documents',
    'legal_document_versions','legal_acceptances'
  )
  union all
  select 'policy',schemaname||'.'||tablename||'.'||policyname,
         jsonb_build_object('roles',roles,'command',cmd,'using',qual,'check',with_check)
  from pg_policies where schemaname='public' and tablename in (
    'profiles','user_roles','artist_onboarding_requests','legal_documents',
    'legal_document_versions','legal_acceptances'
  )
  union all
  select 'trigger',n.nspname||'.'||t.relname||'.'||g.tgname,
         jsonb_build_object('definition',pg_get_triggerdef(g.oid,true),
                            'function',g.tgfoid::regprocedure::text)
  from pg_trigger g join pg_class t on t.oid=g.tgrelid
  join pg_namespace n on n.oid=t.relnamespace
  where not g.tgisinternal and (
    (n.nspname='public' and t.relname in (
      'profiles','user_roles','artist_onboarding_requests','legal_documents',
      'legal_document_versions','legal_acceptances'
    )) or (n.nspname='auth' and t.relname='users')
  )
  union all
  select 'function',n.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')',
         jsonb_build_object('security_definer',p.prosecdef,'leakproof',p.proleakproof,
                            'owner',pg_get_userbyid(p.proowner),'config',p.proconfig,
                            'definition',pg_get_functiondef(p.oid))
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname in ('public','auth') and (
    p.proname='tra_is_admin' or p.proname ilike '%profile%' or
    p.proname ilike '%artist%' or p.proname ilike '%legal%'
  )
  union all
  select 'enum',n.nspname||'.'||t.typname||'.'||e.enumlabel,
         jsonb_build_object('sort_order',e.enumsortorder)
  from pg_enum e join pg_type t on t.oid=e.enumtypid
  join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname in (
    select c.udt_name from information_schema.columns c
    where c.table_schema='public' and (
      (c.table_name='user_roles' and c.column_name='role') or
      (c.table_name='artist_onboarding_requests' and c.column_name='status')
    )
  )
  union all
  select 'table_grant',table_schema||'.'||table_name||'.'||grantee||'.'||privilege_type,
         jsonb_build_object('grantable',is_grantable)
  from information_schema.role_table_grants
  where table_schema='public' and table_name in (
    'profiles','user_roles','artist_onboarding_requests','legal_documents',
    'legal_document_versions','legal_acceptances'
  )
  union all
  select 'column_grant',table_schema||'.'||table_name||'.'||column_name||'.'||grantee||'.'||privilege_type,
         jsonb_build_object('grantable',is_grantable)
  from information_schema.role_column_grants
  where table_schema='public' and table_name in (
    'profiles','user_roles','artist_onboarding_requests','legal_documents',
    'legal_document_versions','legal_acceptances'
  )
  union all
  select 'data_quality',checks.check_name,jsonb_build_object('issue_count',checks.issue_count)
  from (
    select 'duplicate_user_roles' as check_name,count(*) as issue_count from (
      select user_id,role from public.user_roles group by user_id,role having count(*)>1
    ) x
    union all select 'duplicate_artist_onboarding',count(*) from (
      select artist_id from public.artist_onboarding_requests group by artist_id having count(*)>1
    ) x
    union all select 'duplicate_legal_acceptance',count(*) from (
      select user_id,version_id from public.legal_acceptances group by user_id,version_id having count(*)>1
    ) x
    union all select 'profile_without_auth_user',count(*) from public.profiles p
      left join auth.users u on u.id=p.id where u.id is null
    union all select 'role_without_auth_user',count(*) from public.user_roles r
      left join auth.users u on u.id=r.user_id where u.id is null
    union all select 'onboarding_without_profile',count(*) from public.artist_onboarding_requests o
      left join public.profiles p on p.id=o.artist_id where p.id is null
    union all select 'version_without_document',count(*) from public.legal_document_versions v
      left join public.legal_documents d on d.id=v.document_id where d.id is null
    union all select 'acceptance_without_user',count(*) from public.legal_acceptances a
      left join auth.users u on u.id=a.user_id where u.id is null
    union all select 'acceptance_without_version',count(*) from public.legal_acceptances a
      left join public.legal_document_versions v on v.id=a.version_id where v.id is null
  ) checks
)
select section,object_name,detail::text as detail
from inventory
order by section,object_name;
