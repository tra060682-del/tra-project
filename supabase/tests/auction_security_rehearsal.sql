\set ON_ERROR_STOP on
create or replace function pg_temp.assert_true(ok boolean,message text) returns void language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message; end if; end$$;

insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) values
('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000001','authenticated','authenticated','auction.admin@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000002','authenticated','authenticated','auction.artist@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000003','authenticated','authenticated','auction.bidder1@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000004','authenticated','authenticated','auction.bidder2@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now());
insert into public.profiles(id,display_name) select id,'Synthetic auction user' from auth.users where id::text like 'a0000000-%' on conflict(id) do nothing;
insert into public.platform_settings(key,value,description) values('auction_real_money_bidding','false'::jsonb,'Synthetic rehearsal kill switch') on conflict(key) do update set value=excluded.value;
insert into public.user_roles(user_id,role) values
('a0000000-0000-0000-0000-000000000001','admin'),('a0000000-0000-0000-0000-000000000002','artist');
insert into public.artist_profiles(id,user_id,display_name,status,public_visible) values
('a1000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Synthetic Auction Artist','approved',true);
insert into public.legal_documents(id,code,title,audience,is_active) values
('a2000000-0000-0000-0000-000000000001','synthetic_auction_terms','Synthetic auction terms','all',true);
insert into public.legal_document_versions(id,document_id,version,body,content_sha256,is_published) values
('a3000000-0000-0000-0000-000000000001','a2000000-0000-0000-0000-000000000001',1,'Synthetic auction terms only','synthetic-auction-v1',true);
insert into public.legal_acceptances(user_id,version_id,accepted_text_snapshot,acceptance_statement,accepted_content_sha256) values
('a0000000-0000-0000-0000-000000000001','a3000000-0000-0000-0000-000000000001','Synthetic auction terms only','Accepted for rehearsal','synthetic-auction-v1'),
('a0000000-0000-0000-0000-000000000002','a3000000-0000-0000-0000-000000000001','Synthetic auction terms only','Accepted for rehearsal','synthetic-auction-v1'),
('a0000000-0000-0000-0000-000000000003','a3000000-0000-0000-0000-000000000001','Synthetic auction terms only','Accepted for rehearsal','synthetic-auction-v1'),
('a0000000-0000-0000-0000-000000000004','a3000000-0000-0000-0000-000000000001','Synthetic auction terms only','Accepted for rehearsal','synthetic-auction-v1');
insert into public.artworks(id,artist_id,title,description,status,published_at) values
('a4000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001','Synthetic Auction Work','Disposable rehearsal record','published',now());
insert into public.auctions(id,title,slug,starts_at,ends_at,terms_version_id,status,created_by) values
('a5000000-0000-0000-0000-000000000001','Synthetic Auction','synthetic-auction',now()-interval '1 hour',now()+interval '1 hour','a3000000-0000-0000-0000-000000000001','live','a0000000-0000-0000-0000-000000000001');
insert into public.auction_lots(id,auction_id,artwork_id,lot_number,status,opening_paise,increment_paise) values
('a6000000-0000-0000-0000-000000000001','a5000000-0000-0000-0000-000000000001','a4000000-0000-0000-0000-000000000001',1,'live',10000,1000);
insert into public.bidder_eligibility(user_id,status,approved_by,approved_at) values
('a0000000-0000-0000-0000-000000000001','approved','a0000000-0000-0000-0000-000000000001',now()),
('a0000000-0000-0000-0000-000000000002','approved','a0000000-0000-0000-0000-000000000001',now()),
('a0000000-0000-0000-0000-000000000003','approved','a0000000-0000-0000-0000-000000000001',now()),
('a0000000-0000-0000-0000-000000000004','approved','a0000000-0000-0000-0000-000000000001',now());

-- Auction creation is administrator-only; artists can submit only their own artwork.
begin; set local role authenticated; select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000003',true);
do $$begin insert into public.auctions(title,slug,starts_at,ends_at,terms_version_id,created_by) values('Forbidden auction','forbidden-auction',now(),now()+interval '1 day','a3000000-0000-0000-0000-000000000001',auth.uid());raise exception 'ASSERTION_FAILED: bidder created auction';exception when insufficient_privilege then null;when check_violation then null;end$$; rollback;
begin; set local role authenticated; select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000001',true);
insert into public.auctions(title,slug,starts_at,ends_at,terms_version_id,created_by) values('Admin draft','admin-draft',now(),now()+interval '1 day','a3000000-0000-0000-0000-000000000001',auth.uid()); rollback;
begin; set local role authenticated; select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000002',true);
insert into public.auction_submissions(artwork_id,artist_id,artist_note) values('a4000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001','Synthetic submission'); commit;
select pg_temp.assert_true((select status='submitted' from public.auction_submissions where artwork_id='a4000000-0000-0000-0000-000000000001'),'artist auction submission failed');

-- Kill switch rejects even otherwise valid bidders.
begin; set local role authenticated; select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000003',true);
do $$begin perform public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',50000,'a7000000-0000-0000-0000-000000000001');raise exception 'ASSERTION_FAILED: disabled bidding accepted';exception when others then if sqlerrm not like '%BIDDING_NOT_ACTIVATED%' then raise;end if;end$$; rollback;

update public.platform_settings set value='true'::jsonb where key='auction_real_money_bidding';

-- Seller and administrator conflicts are enforced by the RPC.
begin; set local role authenticated; select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000002',true);
do $$begin perform public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',50000,'a7000000-0000-0000-0000-000000000002');raise exception 'ASSERTION_FAILED: self bid accepted';exception when others then if sqlerrm not like '%CONFLICT_OF_INTEREST%' then raise;end if;end$$; rollback;
begin; set local role authenticated; select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000001',true);
do $$begin perform public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',50000,'a7000000-0000-0000-0000-000000000003');raise exception 'ASSERTION_FAILED: admin bid accepted';exception when others then if sqlerrm not like '%CONFLICT_OF_INTEREST%' then raise;end if;end$$; rollback;

select pg_temp.assert_true(not has_table_privilege('anon','public.auction_proxy_bids','SELECT'),'anonymous can read bid ceilings');
select pg_temp.assert_true(not has_table_privilege('authenticated','public.auction_proxy_bids','INSERT'),'browser can insert bid ceilings');
select pg_temp.assert_true(not has_function_privilege('anon','public.place_maximum_bid(uuid,bigint,uuid)','EXECUTE'),'anonymous can execute bid RPC');
select 'auction_fixture_and_security' test_suite,'PASS' result;
