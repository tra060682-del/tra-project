-- Development/disposable rollback only. Refuses to remove auction evidence.
begin;
do $$
begin
  if exists(select 1 from public.auction_bid_events)
     or exists(select 1 from public.auction_bid_requests)
     or exists(select 1 from public.auction_proxy_bids)
     or exists(select 1 from public.auction_disputes) then
    raise exception 'TRA_AUCTION_ROLLBACK_REFUSED: bid or dispute evidence exists';
  end if;
end
$$;
drop view if exists public.public_auction_bid_history;
drop view if exists public.public_auction_lots;
drop function if exists public.close_auction(uuid);
drop function if exists public.place_maximum_bid(uuid,bigint,uuid);
drop table if exists public.auction_watchlists;
drop table if exists public.auction_disputes;
drop table if exists public.auction_bid_events;
drop table if exists public.auction_bid_requests;
drop table if exists public.auction_proxy_bids;
drop table if exists public.auction_lots;
drop table if exists public.auction_submissions;
drop table if exists public.bidder_eligibility;
drop table if exists public.auctions;
drop function if exists public.tra_guard_terminal_auction();
drop function if exists public.tra_guard_terminal_auction_lot();
delete from public.platform_settings where key='auction_real_money_bidding' and value='false'::jsonb;
drop type if exists public.auction_submission_status;
drop type if exists public.bidder_status;
drop type if exists public.auction_lot_status;
drop type if exists public.auction_status;
commit;
