\set ON_ERROR_STOP on
drop schema if exists phase35_rehearsal cascade;
create schema phase35_rehearsal;
create table phase35_rehearsal.tables as select c.relname table_name,c.relrowsecurity,c.relforcerowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p');
create table phase35_rehearsal.columns as select table_name,column_name,ordinal_position,data_type,udt_name,is_nullable,column_default from information_schema.columns where table_schema='public';
create table phase35_rehearsal.constraints as select c.conname,n.nspname schema_name,t.relname table_name,pg_get_constraintdef(c.oid,true) definition from pg_constraint c join pg_class t on t.oid=c.conrelid join pg_namespace n on n.oid=t.relnamespace where n.nspname='public';
create table phase35_rehearsal.policies as select schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check from pg_policies where schemaname='public';
create table phase35_rehearsal.grants as select grantor,grantee,table_schema,table_name,privilege_type,is_grantable from information_schema.role_table_grants where table_schema='public';
create table phase35_rehearsal.functions as select p.proname,pg_get_function_identity_arguments(p.oid) arguments,pg_get_functiondef(p.oid) definition from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public';
create table phase35_rehearsal.triggers as select c.relname table_name,t.tgname,pg_get_triggerdef(t.oid,true) definition from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal;
select count(*) baseline_public_tables from phase35_rehearsal.tables;

