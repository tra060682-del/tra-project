-- READ ONLY: run in the Supabase SQL editor and export every result grid.
-- This script does not mutate schema or data.

select c.table_name,c.ordinal_position,c.column_name,c.data_type,c.udt_schema,c.udt_name,
       c.is_nullable,c.column_default,c.is_identity,c.is_generated
from information_schema.columns c
where c.table_schema='public'
  and c.table_name in (
    'profiles','user_roles','artist_profiles','legal_documents',
    'legal_document_versions','legal_acceptances','artist_onboarding_requests',
    'artist_onboarding_legal_requirements'
  )
order by c.table_name,c.ordinal_position;

select n.nspname as schema_name,t.relname as table_name,c.conname,c.contype,
       pg_get_constraintdef(c.oid,true) as definition
from pg_constraint c
join pg_class t on t.oid=c.conrelid
join pg_namespace n on n.oid=t.relnamespace
where n.nspname='public'
  and t.relname in ('profiles','user_roles','artist_profiles','legal_documents','legal_document_versions','legal_acceptances')
order by t.relname,c.conname;

select schemaname,tablename,indexname,indexdef
from pg_indexes
where schemaname='public'
  and tablename in ('profiles','user_roles','artist_profiles','legal_documents','legal_document_versions','legal_acceptances')
order by tablename,indexname;

select schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check
from pg_policies
where schemaname='public'
  and tablename in ('profiles','user_roles','artist_profiles','legal_documents','legal_document_versions','legal_acceptances')
order by tablename,policyname;

select event_object_table as table_name,trigger_name,event_manipulation,action_timing,
       action_condition,action_statement
from information_schema.triggers
where trigger_schema='public'
  and event_object_table in ('profiles','user_roles','artist_profiles','legal_documents','legal_document_versions','legal_acceptances')
order by event_object_table,trigger_name,event_manipulation;

select n.nspname as schema_name,p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,pg_get_userbyid(p.proowner) as owner,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and (p.proname ilike '%profile%' or p.proname ilike '%role%' or p.proname ilike '%legal%' or p.proname ilike '%artist%')
order by p.proname,arguments;

select table_name,grantee,privilege_type
from information_schema.role_table_grants
where table_schema='public'
  and table_name in ('profiles','user_roles','artist_profiles','legal_documents','legal_document_versions','legal_acceptances')
order by table_name,grantee,privilege_type;

select t.relname as table_name,t.relrowsecurity as rls_enabled,t.relforcerowsecurity as rls_forced
from pg_class t join pg_namespace n on n.oid=t.relnamespace
where n.nspname='public' and t.relkind='r'
  and t.relname in ('profiles','user_roles','artist_profiles','legal_documents','legal_document_versions','legal_acceptances')
order by t.relname;

-- Data-shape checks are deliberately omitted until the column inventory is
-- reviewed; static references here would make this inventory fail precisely
-- when production uses a different key name. Run reviewed count-only checks
-- after mapping the exported definitions. Do not export row contents.
