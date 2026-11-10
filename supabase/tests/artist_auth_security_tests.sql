\set ON_ERROR_STOP on

create or replace function pg_temp.assert_true(ok boolean,message text) returns void
language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message; end if; end$$;

select pg_temp.assert_true(
  (select artist_note='Preserve me' from public.artist_onboarding_requests where id='30000000-0000-0000-0000-000000000001'),
  'existing onboarding record changed'
);
select pg_temp.assert_true(
  (select accepted_text_snapshot='Synthetic terms version one' from public.legal_acceptances where id='60000000-0000-0000-0000-000000000001'),
  'existing acceptance evidence changed'
);
select pg_temp.assert_true((select count(*)=20 from pg_policies where schemaname='public' and tablename in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances'
)), 'existing policy count changed');
select pg_temp.assert_true((select value from public.rehearsal_baseline where key='policy_hash')=(
  select md5(string_agg(concat_ws('|',tablename,policyname,roles::text,cmd,coalesce(qual,''),coalesce(with_check,'')),E'\n' order by tablename,policyname))
  from pg_policies where schemaname='public' and tablename in ('profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances')
), 'existing policy definitions changed');
select pg_temp.assert_true((select value from public.rehearsal_baseline where key='table_grant_hash')=(
  select md5(string_agg(concat_ws('|',table_name,grantee,privilege_type,is_grantable),E'\n' order by table_name,grantee,privilege_type))
  from information_schema.role_table_grants where table_schema='public' and table_name in ('profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances')
), 'existing table grants changed');
select pg_temp.assert_true((select value from public.rehearsal_baseline where key='column_grant_hash')=(
  select md5(coalesce(string_agg(concat_ws('|',c.relname,a.attname,acl.acl_item::text),E'\n' order by c.relname,a.attname,acl.acl_item::text),''))
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
  cross join lateral unnest(a.attacl) acl(acl_item)
  where n.nspname='public' and c.relname in ('profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances')
), 'existing column grants changed');
select pg_temp.assert_true(has_function_privilege('authenticated','public.register_current_user_as_artist(text)','EXECUTE') and
  not has_function_privilege('anon','public.register_current_user_as_artist(text)','EXECUTE'),'registration EXECUTE grants are unsafe');

-- Unverified Supabase Auth user cannot register.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
do $$begin
  perform public.register_current_user_as_artist('Unverified Artist');
  raise exception 'ASSERTION_FAILED: unverified registration succeeded';
exception when others then
  if sqlerrm not like '%VERIFIED_EMAIL_REQUIRED%' then raise; end if;
end$$;
rollback;

-- Verified registration is idempotent and assigns only artist.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
select public.register_current_user_as_artist('New Artist') as first_artist_profile \gset
select public.register_current_user_as_artist('Changed Name Ignored') as repeated_artist_profile \gset
select pg_temp.assert_true(:'first_artist_profile'=:'repeated_artist_profile','registration was not idempotent');
select pg_temp.assert_true((select count(*)=1 from public.user_roles where user_id=auth.uid() and role='artist'),'artist role missing or duplicated');
select pg_temp.assert_true((select count(*)=0 from public.user_roles where user_id=auth.uid() and role='admin'),'registration escalated to admin');
select pg_temp.assert_true((select count(*)=1 from public.artist_onboarding_requests where artist_id=:'first_artist_profile'),'onboarding row missing or duplicated');
select public.save_artist_onboarding('{"display_name":"New Artist Updated","phone":"12345","artist_note":"Draft note"}') as draft_id \gset
select pg_temp.assert_true((select artist_note='Draft note' from public.artist_onboarding_requests where id=:'draft_id'),'draft was not saved');
do $$begin
  perform public.submit_artist_onboarding();
  raise exception 'ASSERTION_FAILED: submission without mandatory acceptance succeeded';
exception when others then
  if sqlerrm not like '%MANDATORY_LEGAL_ACCEPTANCE_REQUIRED%' then raise; end if;
end$$;
select public.accept_artist_legal_version(
  '50000000-0000-0000-0000-000000000001','I accept synthetic terms',null,'rehearsal-agent'
) as acceptance_id \gset
select pg_temp.assert_true((select accepted_text_snapshot='Synthetic terms version one' and accepted_content_sha256='synthetic-sha256-v1'
  from public.legal_acceptances where id=:'acceptance_id'),'server-derived legal evidence incorrect');
select public.submit_artist_onboarding() as submitted_id \gset
select pg_temp.assert_true((select status='submitted' from public.artist_onboarding_requests where id=:'submitted_id'),'onboarding was not submitted');
do $$begin
  insert into public.user_roles(user_id,role) values(auth.uid(),'admin');
  raise exception 'ASSERTION_FAILED: artist assigned admin role';
exception when insufficient_privilege then null;
  when check_violation then null;
end$$;
select pg_temp.assert_true((select count(*)=0 from public.user_roles where user_id=auth.uid() and role='admin'),'admin role persisted');
select pg_temp.assert_true((select count(*)=1 from public.artist_onboarding_requests),'artist can read another artist onboarding row');
update public.artist_onboarding_requests set status='approved' where id=:'submitted_id';
select pg_temp.assert_true((select status='submitted' from public.artist_onboarding_requests where id=:'submitted_id'),'artist approved own onboarding');
commit;

-- Admin policy can approve; artist cannot create the admin permission used here.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
update public.artist_onboarding_requests set status='approved',reviewed_by=auth.uid(),reviewed_at=now()
where id=:'submitted_id';
select pg_temp.assert_true((select status='approved' and reviewed_by=auth.uid() from public.artist_onboarding_requests where id=:'submitted_id'),'admin approval failed');
do $$begin
  update public.legal_acceptances set acceptance_statement='tampered'
  where user_id='10000000-0000-0000-0000-000000000003'
    and version_id='50000000-0000-0000-0000-000000000001';
  raise exception 'ASSERTION_FAILED: admin overwrote acceptance evidence';
exception when others then
  if sqlerrm not like '%LEGAL_ACCEPTANCE_IMMUTABLE%' then raise; end if;
end$$;
commit;

-- Anonymous role cannot execute registration or see artist-only legal content.
begin;
set local role anon;
select set_config('request.jwt.claim.sub','',true);
select pg_temp.assert_true((select count(*)=0 from public.legal_documents),'anonymous artist-legal read leaked');
do $$begin
  perform public.register_current_user_as_artist('Anonymous');
  raise exception 'ASSERTION_FAILED: anonymous registration execute succeeded';
exception when insufficient_privilege then null;
end$$;
rollback;

select 'artist_auth_security_tests' as test_suite,'PASS' as result;
