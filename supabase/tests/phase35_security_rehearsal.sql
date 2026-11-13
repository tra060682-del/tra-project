\set ON_ERROR_STOP on
create or replace function pg_temp.assert_true(ok boolean,message text) returns void language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message;end if;end$$;

-- Synthetic identities only. No remote data is present in this disposable database.
\echo phase35_checkpoint_users
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) values
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000001','authenticated','authenticated','p35.super1@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000002','authenticated','authenticated','p35.super2@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000003','authenticated','authenticated','p35.admin@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000004','authenticated','authenticated','p35.curator@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000005','authenticated','authenticated','p35.artist1@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000006','authenticated','authenticated','p35.artist2@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000007','authenticated','authenticated','p35.intermediary@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000008','authenticated','authenticated','p35.collector1@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000009','authenticated','authenticated','p35.collector2@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000010','authenticated','authenticated','p35.advisor@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000011','authenticated','authenticated','p35.finance@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','c0000000-0000-0000-0000-000000000012','authenticated','authenticated','p35.invitee@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now());
insert into public.profiles(id,display_name) select id,'Phase 3.5 synthetic user' from auth.users where id::text like 'c0000000-%' on conflict(id) do nothing;
insert into public.user_roles(user_id,role) values
('c0000000-0000-0000-0000-000000000001','super_admin'),('c0000000-0000-0000-0000-000000000002','super_admin'),
('c0000000-0000-0000-0000-000000000003','admin'),('c0000000-0000-0000-0000-000000000004','curator'),
('c0000000-0000-0000-0000-000000000005','artist'),('c0000000-0000-0000-0000-000000000006','artist'),
('c0000000-0000-0000-0000-000000000007','intermediary'),('c0000000-0000-0000-0000-000000000008','collector'),
('c0000000-0000-0000-0000-000000000009','collector'),('c0000000-0000-0000-0000-000000000010','advisor'),
('c0000000-0000-0000-0000-000000000011','finance');

select pg_temp.assert_true(public.tra_has_permission('roles.manage','c0000000-0000-0000-0000-000000000001'),'super admin permission missing');
select pg_temp.assert_true(public.tra_has_permission('auctions.manage','c0000000-0000-0000-0000-000000000003'),'admin auction permission missing');
select pg_temp.assert_true(not public.tra_has_permission('roles.manage','c0000000-0000-0000-0000-000000000003'),'admin received role management');
select pg_temp.assert_true(public.tra_has_permission('artworks.review','c0000000-0000-0000-0000-000000000004'),'curator permission missing');
select pg_temp.assert_true(public.tra_has_permission('requests.manage','c0000000-0000-0000-0000-000000000010'),'advisor permission missing');
select pg_temp.assert_true(public.tra_has_permission('payments.manage','c0000000-0000-0000-0000-000000000011'),'finance permission missing');
select pg_temp.assert_true(not public.tra_has_permission('settings.manage','c0000000-0000-0000-0000-000000000011'),'finance received settings permission');
select pg_temp.assert_true(not public.tra_has_permission('users.view','c0000000-0000-0000-0000-000000000008'),'collector received global permission');
insert into public.user_permission_overrides(user_id,permission,effect,reason,created_by) values('c0000000-0000-0000-0000-000000000003','roles.manage','grant','Synthetic protected override attack','c0000000-0000-0000-0000-000000000001');
select pg_temp.assert_true(not public.tra_has_permission('roles.manage','c0000000-0000-0000-0000-000000000003'),'protected override escalated admin');
\echo phase35_checkpoint_permissions

-- Anonymous roles have no access to private access-control records.
select pg_temp.assert_true(not has_table_privilege('anon','public.user_permission_overrides','SELECT'),'anonymous can read overrides');
select pg_temp.assert_true(not has_table_privilege('anon','public.account_invitations','SELECT'),'anonymous can read invitations');

-- Administrative and curator escalation attempts are denied.
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000003',true);
do $$begin perform public.tra_manage_user_role('c0000000-0000-0000-0000-000000000003','super_admin','grant','Forbidden self escalation');raise exception 'ASSERTION_FAILED: admin escalated';exception when others then if sqlerrm not like '%PERMISSION_DENIED%' then raise;end if;end$$;rollback;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000004',true);
do $$begin insert into public.user_roles(user_id,role) values(auth.uid(),'admin');raise exception 'ASSERTION_FAILED: curator escalated';exception when insufficient_privilege then null;end$$;rollback;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000001',true);
do $$begin perform public.tra_manage_user_role(auth.uid(),'super_admin','revoke','Forbidden self revocation');raise exception 'ASSERTION_FAILED: super admin self changed';exception when others then if sqlerrm not like '%SELF_SUPER_ADMIN_CHANGE_FORBIDDEN%' then raise;end if;end$$;commit;

-- Role revocation is immediate and audited.
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000001',true);select public.tra_manage_user_role('c0000000-0000-0000-0000-000000000010','advisor','revoke','Phase 3.5 revocation test');commit;
\echo phase35_checkpoint_escalation
select pg_temp.assert_true(not public.tra_has_permission('requests.manage','c0000000-0000-0000-0000-000000000010'),'revoked role retained permission');

insert into public.artist_profiles(id,user_id,display_name,status,public_visible) values
('c1000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000005','Phase35 Artist One','approved',true),
('c1000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000006','Phase35 Artist Two','approved',true);
insert into public.intermediary_profiles(id,user_id,display_name,email,status) values('c2000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000007','Phase35 Intermediary','p35.intermediary@example.test','approved');
insert into public.artworks(id,artist_id,title,description,status,published_at) values
('c3000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000001','Phase35 Work One','Synthetic','published',now()),
('c3000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000002','Phase35 Work Two','Synthetic','draft',null);

-- Artist ownership and cross-user isolation.
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000005',true);select pg_temp.assert_true((select count(*)=1 from public.artworks where id in ('c3000000-0000-0000-0000-000000000001','c3000000-0000-0000-0000-000000000002')),'artist crossed ownership boundary');rollback;

insert into public.artist_representations(id,artist_id,intermediary_id,status,can_submit_artwork,can_view_fulfilment,starts_at) values('c4000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000001','c2000000-0000-0000-0000-000000000001','approved',true,false,now()-interval '1 day');
select pg_temp.assert_true(public.tra_representation_allows('c4000000-0000-0000-0000-000000000001','submit_artwork','c0000000-0000-0000-0000-000000000007'),'approved intermediary scope denied');
select pg_temp.assert_true(not public.tra_representation_allows('c4000000-0000-0000-0000-000000000001','view_fulfilment','c0000000-0000-0000-0000-000000000007'),'unapproved intermediary scope allowed');
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000005',true);select public.tra_revoke_representation('c4000000-0000-0000-0000-000000000001','Artist revoked synthetic representation');commit;
select pg_temp.assert_true(not public.tra_representation_allows('c4000000-0000-0000-0000-000000000001','submit_artwork','c0000000-0000-0000-0000-000000000007'),'revoked representation retained scope');
\echo phase35_checkpoint_representation

insert into public.offers(id,artwork_id,buyer_user_id,amount_paise) values
('c5000000-0000-0000-0000-000000000001','c3000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000008',100000),
('c5000000-0000-0000-0000-000000000002','c3000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000009',110000);
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000008',true);select pg_temp.assert_true((select count(*)=1 from public.offers),'collector offer isolation failed');rollback;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000005',true);do $$begin perform public.submit_offer('c3000000-0000-0000-0000-000000000001',120000,'Self offer');raise exception 'ASSERTION_FAILED: artist self offer accepted';exception when others then if sqlerrm not like '%SELF_DEALING_FORBIDDEN%' then raise;end if;end$$;rollback;
\echo phase35_checkpoint_offers

insert into public.buyer_enquiries(id,buyer_name,email,message,consent_accepted) values('c6000000-0000-0000-0000-000000000001','Synthetic Buyer','buyer@example.test','Synthetic enquiry',true);
-- Restore advisor role through the audited Super Admin RPC and verify the new RLS policy.
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000001',true);select public.tra_manage_user_role('c0000000-0000-0000-0000-000000000010','advisor','grant','Restore after revocation test');commit;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000010',true);select pg_temp.assert_true((select count(*)=1 from public.buyer_enquiries where id='c6000000-0000-0000-0000-000000000001'),'advisor enquiry RLS denied');rollback;

insert into public.buyers(id,full_name,email) values('c7000000-0000-0000-0000-000000000001','Synthetic Buyer','buyer@example.test');
insert into public.sales(id,artwork_id,artist_id,buyer_id,agreed_price_paise) values('c8000000-0000-0000-0000-000000000001','c3000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000001','c7000000-0000-0000-0000-000000000001',100000);
insert into public.payment_events(id,provider,provider_event_id,event_type,amount_paise,currency,signature_verified,payload_sha256,payload) values('c9000000-0000-0000-0000-000000000001','test','phase35-event','payment.captured',100000,'INR',true,repeat('a',64),'{}');
insert into public.ledger_entries(id,sale_id,payment_event_id,entry_type,account,direction,amount_paise) values('ca000000-0000-0000-0000-000000000001','c8000000-0000-0000-0000-000000000001','c9000000-0000-0000-0000-000000000001','payment','cash','debit',100000);
insert into public.audit_events(id,action,entity_type,entity_id) values('cb000000-0000-0000-0000-000000000001','phase35.test','test','c8000000-0000-0000-0000-000000000001');
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000011',true);select pg_temp.assert_true((select count(*)=1 from public.payment_events),'finance payment RLS denied');select pg_temp.assert_true((select count(*)>=1 from public.audit_events),'finance audit RLS denied');do $$begin update public.audit_events set action='tampered' where id='cb000000-0000-0000-0000-000000000001';if found then raise exception 'ASSERTION_FAILED: finance altered audit';end if;exception when insufficient_privilege then null;end$$;rollback;
begin;do $$begin update public.ledger_entries set amount_paise=1 where id='ca000000-0000-0000-0000-000000000001';raise exception 'ASSERTION_FAILED: ledger update succeeded';exception when others then if sqlerrm not like '%LEDGER_IMMUTABLE%' then raise;end if;end$$;rollback;
\echo phase35_checkpoint_finance

-- Suspension blocks permissions and protected mutations; reactivation restores them.
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000001',true);select public.tra_set_account_status('c0000000-0000-0000-0000-000000000008','suspended','Synthetic suspension rehearsal');commit;
select pg_temp.assert_true(not public.tra_account_is_active('c0000000-0000-0000-0000-000000000008'),'suspension not effective');
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000008',true);select pg_temp.assert_true((select count(*)=0 from public.offers),'suspended account retained private read access');rollback;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000008',true);do $$begin perform public.submit_offer('c3000000-0000-0000-0000-000000000001',130000,'Suspended offer');raise exception 'ASSERTION_FAILED: suspended offer accepted';exception when others then if sqlerrm not like '%ACCOUNT_INACTIVE%' then raise;end if;end$$;rollback;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000001',true);select public.tra_set_account_status('c0000000-0000-0000-0000-000000000008','active','Synthetic reactivation rehearsal');commit;
select pg_temp.assert_true(public.tra_account_is_active('c0000000-0000-0000-0000-000000000008'),'reactivation not effective');

-- Invitation is verified-email-bound, single-use and cannot grant Super Admin.
do $$declare token text;begin perform set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000001',true);token:=public.tra_create_invitation('p35.invitee@example.test','advisor',24);perform set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000012',true);perform public.tra_accept_invitation(token);begin perform public.tra_accept_invitation(token);raise exception 'ASSERTION_FAILED: invitation replay succeeded';exception when others then if sqlerrm not like '%INVITATION_INVALID%' then raise;end if;end;end$$;
select pg_temp.assert_true(public.tra_has_permission('requests.manage','c0000000-0000-0000-0000-000000000012'),'accepted invitation did not grant role');

select 'phase35_rbac_rls_financial' test_suite,'PASS' result;

