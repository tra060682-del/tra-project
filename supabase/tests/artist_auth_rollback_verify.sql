\set ON_ERROR_STOP on

create or replace function pg_temp.assert_true(ok boolean,message text) returns void
language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message; end if; end$$;

select pg_temp.assert_true(to_regprocedure('public.accept_artist_legal_version(uuid,text,inet,text)') is null,'accept RPC remains');
select pg_temp.assert_true(to_regprocedure('public.save_artist_onboarding(jsonb)') is null,'save RPC remains');
select pg_temp.assert_true(to_regprocedure('public.submit_artist_onboarding()') is null,'submit RPC remains');
select pg_temp.assert_true(to_regprocedure('public.tra_prepare_legal_acceptance()') is null,'acceptance trigger function remains');
select pg_temp.assert_true(not exists(select 1 from pg_trigger where tgname='tra_legal_acceptance_immutable_snapshot' and not tgisinternal),'acceptance trigger remains');
select pg_temp.assert_true(to_regprocedure('public.register_current_user_as_artist(text)') is not null,'original registration function missing');
select pg_temp.assert_true(position('artist_onboarding_requests' in pg_get_functiondef('public.register_current_user_as_artist(text)'::regprocedure))=0,'registration function was not restored');
select pg_temp.assert_true((select count(*)=20 from pg_policies where schemaname='public' and tablename in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances'
)), 'pre-existing policies changed');
select pg_temp.assert_true((select value from public.rehearsal_baseline where key='policy_hash')=(
  select md5(string_agg(concat_ws('|',tablename,policyname,roles::text,cmd,coalesce(qual,''),coalesce(with_check,'')),E'\n' order by tablename,policyname))
  from pg_policies where schemaname='public' and tablename in ('profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances')
), 'pre-existing policy definitions changed');
select pg_temp.assert_true((select value from public.rehearsal_baseline where key='table_grant_hash')=(
  select md5(string_agg(concat_ws('|',table_name,grantee,privilege_type,is_grantable),E'\n' order by table_name,grantee,privilege_type))
  from information_schema.role_table_grants where table_schema='public' and table_name in ('profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances')
), 'pre-existing table grants changed');
select pg_temp.assert_true((select value from public.rehearsal_baseline where key='column_grant_hash')=(
  select md5(coalesce(string_agg(concat_ws('|',c.relname,a.attname,acl.acl_item::text),E'\n' order by c.relname,a.attname,acl.acl_item::text),''))
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
  cross join lateral unnest(a.attacl) acl(acl_item)
  where n.nspname='public' and c.relname in ('profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances')
), 'pre-existing column grants changed');
select pg_temp.assert_true(has_function_privilege('authenticated','public.register_current_user_as_artist(text)','EXECUTE') and
  has_function_privilege('service_role','public.register_current_user_as_artist(text)','EXECUTE') and
  not has_function_privilege('anon','public.register_current_user_as_artist(text)','EXECUTE'),'registration function grants were not restored');
select pg_temp.assert_true((select artist_note='Preserve me' from public.artist_onboarding_requests where id='30000000-0000-0000-0000-000000000001'),'pre-existing onboarding changed');
select pg_temp.assert_true((select accepted_text_snapshot='Synthetic terms version one' from public.legal_acceptances where id='60000000-0000-0000-0000-000000000001'),'pre-existing acceptance changed');
select pg_temp.assert_true(exists(select 1 from information_schema.columns where table_schema='public' and table_name='legal_acceptances' and column_name='acceptance_statement'),'retained evidence statement column missing');
select pg_temp.assert_true(exists(select 1 from information_schema.columns where table_schema='public' and table_name='legal_acceptances' and column_name='accepted_content_sha256'),'retained evidence hash column missing');
select 'artist_auth_rollback_verify' as test_suite,'PASS' as result;
