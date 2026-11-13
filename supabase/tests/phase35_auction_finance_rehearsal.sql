\set ON_ERROR_STOP on
create or replace function pg_temp.assert_true(ok boolean,message text) returns void language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message;end if;end$$;
insert into public.legal_acceptances(user_id,version_id,accepted_text_snapshot,acceptance_statement,accepted_content_sha256) values('c0000000-0000-0000-0000-000000000011','a3000000-0000-0000-0000-000000000001','Synthetic auction terms only','Accepted for finance conflict test','synthetic-auction-v1');
insert into public.bidder_eligibility(user_id,status,approved_by,approved_at) values('c0000000-0000-0000-0000-000000000011','approved','a0000000-0000-0000-0000-000000000001',now());
begin;set local role authenticated;select set_config('request.jwt.claim.sub','c0000000-0000-0000-0000-000000000011',true);
do $$begin perform public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',70000,'cc000000-0000-0000-0000-000000000001');raise exception 'ASSERTION_FAILED: finance bid accepted';exception when others then if sqlerrm not like '%OPERATIONAL_ROLE_CANNOT_BID%' then raise;end if;end$$;rollback;
select pg_temp.assert_true((select count(*)=0 from public.auction_proxy_bids where user_id='c0000000-0000-0000-0000-000000000011'),'finance bid state persisted');
select 'phase35_finance_auction_conflict' test_suite,'PASS' result;
