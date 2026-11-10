-- tRA production schema inventory: read only, one consolidated result set.
-- Expected output columns: section, object_schema, object_name, details.
-- Safe for the Supabase SQL Editor's normal administrative execution context.

with
target_tables(object_schema,object_name) as (
  values
    ('public','profiles'),
    ('public','artist_profiles'),
    ('public','user_roles'),
    ('public','artist_onboarding_requests'),
    ('public','legal_documents'),
    ('public','legal_document_versions'),
    ('public','legal_acceptances')
),
target_relations as (
  select c.oid,n.nspname as object_schema,c.relname as object_name,c.relowner,
         c.relkind,c.relrowsecurity,c.relforcerowsecurity,c.relacl
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  join target_tables t on t.object_schema=n.nspname and t.object_name=c.relname
),
relevant_triggers as (
  select g.oid,g.tgrelid,g.tgfoid,g.tgname,g.tgenabled,
         n.nspname as object_schema,c.relname as table_name
  from pg_trigger g
  join pg_class c on c.oid=g.tgrelid
  join pg_namespace n on n.oid=c.relnamespace
  where not g.tgisinternal and (
    exists(select 1 from target_tables t where t.object_schema=n.nspname and t.object_name=c.relname)
    or (n.nspname='auth' and c.relname='users')
  )
),
relevant_function_oids as (
  select distinct tgfoid as oid from relevant_triggers
  union
  select p.oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname in ('public','auth') and (
    p.proname='tra_is_admin'
    or p.proname like 'tra_%'
    or p.proname ilike '%profile%'
    or p.proname ilike '%artist%'
    or p.proname ilike '%legal%'
    or p.proname ilike '%updated%'
  )
),
expected_sections(section) as (
  values
    ('column'),
    ('primary_key_constraint'),
    ('unique_constraint'),
    ('foreign_key_constraint'),
    ('check_constraint'),
    ('index'),
    ('rls_table'),
    ('rls_policy'),
    ('trigger'),
    ('function'),
    ('enum'),
    ('table_grant'),
    ('column_grant'),
    ('function_grant'),
    ('object_catalog'),
    ('data_quality')
),
inventory(section,object_schema,object_name,details) as (
  select 'column',c.table_schema,c.table_name||'.'||c.column_name,
         jsonb_build_object(
           'table',c.table_name,
           'column',c.column_name,
           'ordinal_position',c.ordinal_position,
           'data_type',c.data_type,
           'udt_schema',c.udt_schema,
           'udt_name',c.udt_name,
           'nullable',c.is_nullable,
           'default',c.column_default,
           'identity',c.is_identity,
           'generated',c.is_generated
         )
  from information_schema.columns c
  join target_tables t on t.object_schema=c.table_schema and t.object_name=c.table_name

  union all
  select
    case c.contype
      when 'p' then 'primary_key_constraint'
      when 'u' then 'unique_constraint'
      when 'f' then 'foreign_key_constraint'
      when 'c' then 'check_constraint'
    end,
    n.nspname,
    t.relname||'.'||c.conname,
    jsonb_build_object(
      'table',t.relname,
      'constraint_name',c.conname,
      'validated',c.convalidated,
      'definition',pg_get_constraintdef(c.oid,true),
      'referenced_schema',rn.nspname,
      'referenced_table',rt.relname,
      'delete_action',case c.confdeltype
        when 'a' then 'NO ACTION' when 'r' then 'RESTRICT'
        when 'c' then 'CASCADE' when 'n' then 'SET NULL'
        when 'd' then 'SET DEFAULT' else null end,
      'update_action',case c.confupdtype
        when 'a' then 'NO ACTION' when 'r' then 'RESTRICT'
        when 'c' then 'CASCADE' when 'n' then 'SET NULL'
        when 'd' then 'SET DEFAULT' else null end
    )
  from pg_constraint c
  join pg_class t on t.oid=c.conrelid
  join pg_namespace n on n.oid=t.relnamespace
  left join pg_class rt on rt.oid=c.confrelid
  left join pg_namespace rn on rn.oid=rt.relnamespace
  where c.contype in ('p','u','f','c')
    and exists(select 1 from target_tables x where x.object_schema=n.nspname and x.object_name=t.relname)

  union all
  select 'index',i.schemaname,i.indexname,
         jsonb_build_object('table',i.tablename,'definition',i.indexdef)
  from pg_indexes i
  join target_tables t on t.object_schema=i.schemaname and t.object_name=i.tablename

  union all
  select 'rls_table',r.object_schema,r.object_name,
         jsonb_build_object(
           'enabled',r.relrowsecurity,
           'forced',r.relforcerowsecurity,
           'owner',pg_get_userbyid(r.relowner)
         )
  from target_relations r

  union all
  select 'rls_policy',p.schemaname,p.tablename||'.'||p.policyname,
         jsonb_build_object(
           'table',p.tablename,'policy_name',p.policyname,
           'permissive',p.permissive,'roles',p.roles,
           'command',p.cmd,'using',p.qual,'with_check',p.with_check
         )
  from pg_policies p
  join target_tables t on t.object_schema=p.schemaname and t.object_name=p.tablename

  union all
  select 'trigger',t.object_schema,t.table_name||'.'||t.tgname,
         jsonb_build_object(
           'table',t.table_name,
           'trigger_name',t.tgname,
           'enabled_mode',case t.tgenabled
             when 'O' then 'ORIGIN' when 'D' then 'DISABLED'
             when 'R' then 'REPLICA' when 'A' then 'ALWAYS' end,
           'function',t.tgfoid::regprocedure::text,
           'definition',pg_get_triggerdef(t.oid,true)
         )
  from relevant_triggers t

  union all
  select 'function',n.nspname,p.proname||'('||pg_get_function_identity_arguments(p.oid)||')',
         jsonb_build_object(
           'owner',pg_get_userbyid(p.proowner),
           'language',l.lanname,
           'security_mode',case when p.prosecdef then 'SECURITY DEFINER' else 'SECURITY INVOKER' end,
           'leakproof',p.proleakproof,
           'volatility',case p.provolatile when 'i' then 'IMMUTABLE' when 's' then 'STABLE' else 'VOLATILE' end,
           'parallel',case p.proparallel when 's' then 'SAFE' when 'r' then 'RESTRICTED' else 'UNSAFE' end,
           'configuration',p.proconfig,
           'search_path',(
             select split_part(setting,'=',2)
             from unnest(coalesce(p.proconfig,array[]::text[])) as settings(setting)
             where setting like 'search_path=%' limit 1
           ),
           'definition',pg_get_functiondef(p.oid)
         )
  from relevant_function_oids f
  join pg_proc p on p.oid=f.oid
  join pg_namespace n on n.oid=p.pronamespace
  join pg_language l on l.oid=p.prolang

  union all
  select 'enum',n.nspname,t.typname||'.'||e.enumlabel,
         jsonb_build_object(
           'enum_type',t.typname,
           'value',e.enumlabel,
           'sort_order',e.enumsortorder,
           'owner',pg_get_userbyid(t.typowner)
         )
  from pg_enum e
  join pg_type t on t.oid=e.enumtypid
  join pg_namespace n on n.oid=t.typnamespace
  where (n.nspname,t.typname) in (
    select c.udt_schema,c.udt_name
    from information_schema.columns c
    join target_tables x on x.object_schema=c.table_schema and x.object_name=c.table_name
    where c.data_type='USER-DEFINED'
  )

  union all
  select 'table_grant',r.object_schema,r.object_name||'.'||coalesce(grantee.rolname,'PUBLIC')||'.'||acl.privilege_type,
         jsonb_build_object(
           'table',r.object_name,
           'grantor',coalesce(grantor.rolname,'PUBLIC'),
           'grantee',coalesce(grantee.rolname,'PUBLIC'),
           'privilege',acl.privilege_type,
           'grantable',acl.is_grantable
         )
  from target_relations r
  -- Flatten any stored ACL dimensions first, then pass exactly one ACL item in
  -- a one-dimensional array to aclexplode().
  cross join lateral unnest(coalesce(r.relacl,acldefault('r',r.relowner))) as raw_acl(acl_item)
  cross join lateral aclexplode(array[raw_acl.acl_item]::aclitem[]) as acl
  left join pg_roles grantor on grantor.oid=acl.grantor
  left join pg_roles grantee on grantee.oid=acl.grantee

  union all
  select 'column_grant',n.nspname,c.relname||'.'||a.attname||'.'||coalesce(grantee.rolname,'PUBLIC')||'.'||acl.privilege_type,
         jsonb_build_object(
           'table',c.relname,
           'column',a.attname,
           'grantor',coalesce(grantor.rolname,'PUBLIC'),
           'grantee',coalesce(grantee.rolname,'PUBLIC'),
           'privilege',acl.privilege_type,
           'grantable',acl.is_grantable
         )
  from pg_attribute a
  join pg_class c on c.oid=a.attrelid
  join pg_namespace n on n.oid=c.relnamespace
  join target_tables x on x.object_schema=n.nspname and x.object_name=c.relname
  -- NULL attacl means there are no explicit column grants. unnest(NULL)
  -- returns no rows and avoids the zero-dimensional '{}' ACL array.
  cross join lateral unnest(a.attacl) as raw_acl(acl_item)
  cross join lateral aclexplode(array[raw_acl.acl_item]::aclitem[]) as acl
  left join pg_roles grantor on grantor.oid=acl.grantor
  left join pg_roles grantee on grantee.oid=acl.grantee
  where a.attnum>0 and not a.attisdropped

  union all
  select 'function_grant',n.nspname,p.proname||'('||pg_get_function_identity_arguments(p.oid)||').'
         ||coalesce(grantee.rolname,'PUBLIC')||'.'||acl.privilege_type,
         jsonb_build_object(
           'function',p.proname||'('||pg_get_function_identity_arguments(p.oid)||')',
           'grantor',coalesce(grantor.rolname,'PUBLIC'),
           'grantee',coalesce(grantee.rolname,'PUBLIC'),
           'privilege',acl.privilege_type,
           'grantable',acl.is_grantable
         )
  from relevant_function_oids f
  join pg_proc p on p.oid=f.oid
  join pg_namespace n on n.oid=p.pronamespace
  cross join lateral unnest(coalesce(p.proacl,acldefault('f',p.proowner))) as raw_acl(acl_item)
  cross join lateral aclexplode(array[raw_acl.acl_item]::aclitem[]) as acl
  left join pg_roles grantor on grantor.oid=acl.grantor
  left join pg_roles grantee on grantee.oid=acl.grantee

  union all
  select 'object_catalog',r.object_schema,r.object_name,
         jsonb_build_object(
           'object_kind','table',
           'relation_kind',r.relkind,
           'owner',pg_get_userbyid(r.relowner)
         )
  from target_relations r

  union all
  select 'object_catalog',n.nspname,c.relname,
         jsonb_build_object(
           'object_kind','index',
           'table_schema',tn.nspname,
           'table_name',t.relname,
           'owner',pg_get_userbyid(c.relowner)
         )
  from pg_index i
  join pg_class c on c.oid=i.indexrelid
  join pg_namespace n on n.oid=c.relnamespace
  join pg_class t on t.oid=i.indrelid
  join pg_namespace tn on tn.oid=t.relnamespace
  join target_tables x on x.object_schema=tn.nspname and x.object_name=t.relname

  union all
  select 'object_catalog',n.nspname,p.proname||'('||pg_get_function_identity_arguments(p.oid)||')',
         jsonb_build_object('object_kind','function','owner',pg_get_userbyid(p.proowner))
  from relevant_function_oids f
  join pg_proc p on p.oid=f.oid
  join pg_namespace n on n.oid=p.pronamespace

  union all
  select 'object_catalog',t.object_schema,t.table_name||'.'||t.tgname,
         jsonb_build_object('object_kind','trigger','function',t.tgfoid::regprocedure::text)
  from relevant_triggers t

  union all
  select 'object_catalog',p.schemaname,p.tablename||'.'||p.policyname,
         jsonb_build_object('object_kind','policy','table',p.tablename)
  from pg_policies p
  join target_tables t on t.object_schema=p.schemaname and t.object_name=p.tablename

  union all
  select 'object_catalog',n.nspname,t.typname,
         jsonb_build_object('object_kind','enum','owner',pg_get_userbyid(t.typowner))
  from pg_type t
  join pg_namespace n on n.oid=t.typnamespace
  where exists(select 1 from pg_enum e where e.enumtypid=t.oid)
    and (n.nspname,t.typname) in (
      select c.udt_schema,c.udt_name
      from information_schema.columns c
      join target_tables x on x.object_schema=c.table_schema and x.object_name=c.table_name
      where c.data_type='USER-DEFINED'
    )

  union all
  select 'data_quality','public',checks.check_name,
         jsonb_build_object('issue_count',checks.issue_count)
  from (
    select 'duplicate_user_roles' as check_name,count(*) as issue_count from (
      select user_id,role from public.user_roles group by user_id,role having count(*)>1
    ) q
    union all select 'duplicate_artist_onboarding',count(*) from (
      select artist_id from public.artist_onboarding_requests group by artist_id having count(*)>1
    ) q
    union all select 'duplicate_legal_acceptance',count(*) from (
      select user_id,version_id from public.legal_acceptances group by user_id,version_id having count(*)>1
    ) q
    union all select 'profile_without_auth_user',count(*) from public.profiles p
      left join auth.users u on u.id=p.id where u.id is null
    union all select 'artist_profile_without_auth_user',count(*) from public.artist_profiles p
      left join auth.users u on u.id=p.user_id where u.id is null
    union all select 'duplicate_artist_profile_user',count(*) from (
      select user_id from public.artist_profiles group by user_id having count(*)>1
    ) q
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
),
inventory_with_empty_sections as (
  select * from inventory
  union all
  select e.section,'inventory','__no_rows__',
         jsonb_build_object('empty',true,'row_count',0)
  from expected_sections e
  where not exists(select 1 from inventory i where i.section=e.section)
),
manifest as (
  select 'export_manifest'::text as section,
         'inventory'::text as object_schema,
         e.section::text as object_name,
         jsonb_build_object(
           'row_count',count(i.object_name),
           'empty',count(i.object_name)=0,
           'expected',true
         ) as details
  from expected_sections e
  left join inventory i on i.section=e.section
  group by e.section
)
select section,object_schema,object_name,details::text as details
from inventory_with_empty_sections
union all
select section,object_schema,object_name,details::text
from manifest
order by section,object_schema,object_name;
