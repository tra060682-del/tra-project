\set ON_ERROR_STOP on
create or replace function pg_temp.assert_true(ok boolean,message text) returns void language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message; end if; end$$;
select pg_temp.assert_true((select bid_count=2 and current_paise=31000 and reserve_met from public.auction_lots where id='a6000000-0000-0000-0000-000000000001'),'concurrent proxy result is incorrect');
select pg_temp.assert_true((select count(*)=2 from public.auction_bid_events where lot_id='a6000000-0000-0000-0000-000000000001'),'bid audit events missing');
-- Replaying an identical request is idempotent and does not increment bid_count.
begin;set local role authenticated;select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000003',true);
select public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',50000,'a7000000-0000-0000-0000-000000000011');commit;
select pg_temp.assert_true((select bid_count=2 from public.auction_lots where id='a6000000-0000-0000-0000-000000000001'),'idempotent replay changed bid count');
update public.auctions set ends_at=now()-interval '1 second' where id='a5000000-0000-0000-0000-000000000001';
begin;set local role authenticated;select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000001',true);
select public.close_auction('a6000000-0000-0000-0000-000000000001');commit;
select pg_temp.assert_true((select status='sold' and payment_status='not_requested' and closed_at is not null from public.auction_lots where id='a6000000-0000-0000-0000-000000000001'),'auction close result incorrect');
select pg_temp.assert_true((select count(*)=3 from public.audit_events where entity_id='a6000000-0000-0000-0000-000000000001'),'audit log is incomplete');
begin;set local role authenticated;select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000001',true);
do $$begin update public.auction_lots set current_paise=1 where id='a6000000-0000-0000-0000-000000000001';raise exception 'ASSERTION_FAILED: admin manipulated bid state';exception when insufficient_privilege then null;end$$;rollback;
do $$begin update public.auction_lots set opening_paise=20000 where id='a6000000-0000-0000-0000-000000000001';raise exception 'ASSERTION_FAILED: terminal lot was edited';exception when others then if sqlerrm not like '%TERMINAL_AUCTION_LOT_IMMUTABLE%' then raise;end if;end$$;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000004',true);
do $$begin perform public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',60000,'a7000000-0000-0000-0000-000000000013');raise exception 'ASSERTION_FAILED: closed lot accepted a bid';exception when others then if sqlerrm not like '%AUCTION_NOT_OPEN%' then raise;end if;end$$;rollback;
select 'auction_concurrency_close_audit' test_suite,'PASS' result;
