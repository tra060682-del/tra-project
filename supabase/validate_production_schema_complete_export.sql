-- READ ONLY validation companion for production_schema_complete_export.sql.
-- A zero source_rows value is valid and will be represented by __no_rows__ in
-- the complete export. This query itself returns exactly one result set.

with
target_tables(object_schema,object_name) as (
  values
    ('public','profiles'),('public','artist_profiles'),('public','user_roles'),
    ('public','artist_onboarding_requests'),('public','legal_documents'),
    ('public','legal_document_versions'),('public','legal_acceptances')
),
target_relations as (
  select c.oid,c.relowner,c.relacl
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  join target_tables t on t.object_schema=n.nspname and t.object_name=c.relname
),
target_triggers as (
  select g.tgfoid
  from pg_trigger g join pg_class c on c.oid=g.tgrelid
  join pg_namespace n on n.oid=c.relnamespace
  where not g.tgisinternal and (
    exists(select 1 from target_tables t where t.object_schema=n.nspname and t.object_name=c.relname)
    or (n.nspname='auth' and c.relname='users')
  )
),
section_counts(section,source_rows) as (
  select 'column',count(*) from information_schema.columns c
  join target_tables t on t.object_schema=c.table_schema and t.object_name=c.table_name
  union all
  select 'primary_key_constraint',count(*) from pg_constraint c
  where c.contype='p' and c.conrelid in (select oid from target_relations)
  union all
  select 'unique_constraint',count(*) from pg_constraint c
  where c.contype='u' and c.conrelid in (select oid from target_relations)
  union all
  select 'foreign_key_constraint',count(*) from pg_constraint c
  where c.contype='f' and c.conrelid in (select oid from target_relations)
  union all
  select 'check_constraint',count(*) from pg_constraint c
  where c.contype='c' and c.conrelid in (select oid from target_relations)
  union all
  select 'index',count(*) from pg_index i where i.indrelid in (select oid from target_relations)
  union all
  select 'rls_table',count(*) from target_relations
  union all
  select 'rls_policy',count(*) from pg_policies p
  join target_tables t on t.object_schema=p.schemaname and t.object_name=p.tablename
  union all
  select 'trigger',count(*) from target_triggers
  union all
  select 'function',count(distinct p.oid) from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where p.oid in (select tgfoid from target_triggers)
     or (n.nspname in ('public','auth') and (
       p.proname='tra_is_admin' or p.proname like 'tra_%'
       or p.proname ilike '%profile%' or p.proname ilike '%artist%'
       or p.proname ilike '%legal%' or p.proname ilike '%updated%'
     ))
  union all
  select 'enum',count(*) from pg_enum e join pg_type ty on ty.oid=e.enumtypid
  where (ty.typnamespace::regnamespace::text,ty.typname) in (
    select c.udt_schema,c.udt_name from information_schema.columns c
    join target_tables t on t.object_schema=c.table_schema and t.object_name=c.table_name
    where c.data_type='USER-DEFINED'
  )
  union all
  select 'table_grant',count(*) from target_relations r
  cross join lateral unnest(coalesce(r.relacl,acldefault('r',r.relowner))) as raw_acl(acl_item)
  cross join lateral aclexplode(array[raw_acl.acl_item]::aclitem[]) as acl
  union all
  select 'column_grant',count(*) from pg_attribute a
  where a.attrelid in (select oid from target_relations) and a.attnum>0
    and not a.attisdropped and a.attacl is not null
  union all
  select 'function_grant',count(*) from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  cross join lateral unnest(coalesce(p.proacl,acldefault('f',p.proowner))) as raw_acl(acl_item)
  cross join lateral aclexplode(array[raw_acl.acl_item]::aclitem[]) as acl
  where p.oid in (select tgfoid from target_triggers)
     or (n.nspname in ('public','auth') and (
       p.proname='tra_is_admin' or p.proname like 'tra_%'
       or p.proname ilike '%profile%' or p.proname ilike '%artist%'
       or p.proname ilike '%legal%' or p.proname ilike '%updated%'
     ))
  union all
  select 'object_catalog',count(*) from target_relations
  union all
  select 'data_quality',11::bigint
)
select section,source_rows,
       case when source_rows=0 then 'SECTION_WILL_USE___no_rows___PLACEHOLDER'
            else 'SECTION_HAS_SOURCE_ROWS' end as validation_status
from section_counts
order by section;
