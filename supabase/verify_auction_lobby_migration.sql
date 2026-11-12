-- Read-only auction migration verification. Every critical_issues result must be zero.
with required_tables(name) as (values
 ('auctions'),('auction_lots'),('bidder_eligibility'),('auction_submissions'),('auction_proxy_bids'),
 ('auction_bid_requests'),('auction_bid_events'),('auction_watchlists'),('auction_disputes')
)
select 'missing_tables' check_name,count(*)::bigint critical_issues
from required_tables where to_regclass('public.'||name) is null
union all
select 'missing_rpcs',count(*) from (values
 ('public.place_maximum_bid(uuid,bigint,uuid)'),('public.close_auction(uuid)')
) f(signature) where to_regprocedure(signature) is null
union all
select 'rls_not_enabled',count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname like 'auction%' and c.relkind='r' and not c.relrowsecurity
union all
select 'anon_mutation_grants',count(*) from information_schema.role_table_grants
where grantee='anon' and table_schema='public' and table_name like 'auction%' and privilege_type<>'SELECT'
union all
select 'authenticated_proxy_writes',count(*) from information_schema.role_table_grants
where grantee='authenticated' and table_schema='public' and table_name in ('auction_proxy_bids','auction_bid_requests','auction_bid_events')
  and privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE')
union all
select 'public_rpc_execute',count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('place_maximum_bid','close_auction') and has_function_privilege('public',p.oid,'execute')
union all
select 'bid_state_update_grants',count(*) from information_schema.column_privileges
where grantee='authenticated' and table_schema='public' and table_name='auction_lots'
  and column_name in ('current_paise','current_leader','reserve_met','bid_count','closed_at') and privilege_type='UPDATE'
union all
select 'missing_terminal_guards',count(*) from (values('tra_guard_terminal_auction'),('tra_guard_terminal_auction_lot')) g(name)
where not exists(select 1 from pg_trigger where tgname=g.name and not tgisinternal)
union all
select 'bidding_gate_not_disabled',count(*) from public.platform_settings
where key='auction_real_money_bidding' and value <> 'false'::jsonb
union all
select 'duplicate_active_artwork_lots',count(*) from (
 select artwork_id from public.auction_lots where status in ('approved','scheduled','live') group by artwork_id having count(*)>1
) d
union all
select 'orphan_lots',count(*) from public.auction_lots l
left join public.auctions a on a.id=l.auction_id left join public.artworks w on w.id=l.artwork_id
where a.id is null or w.id is null
union all
select 'invalid_bid_state',count(*) from public.auction_lots
where (current_paise is null)<>(current_leader is null) or (bid_count=0)<>(current_paise is null);
