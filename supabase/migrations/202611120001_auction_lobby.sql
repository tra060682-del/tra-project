-- tRA auction lobby: additive, terms-gated, and disabled for real-money bidding by default.
-- Apply only after 202611090001_artist_auth.sql. Currency values are integer paise.
begin;

do $$
begin
  if to_regclass('public.artworks') is null
     or to_regclass('public.artist_profiles') is null
     or to_regclass('public.legal_document_versions') is null
     or to_regclass('public.legal_acceptances') is null
     or to_regclass('public.platform_settings') is null
     or to_regclass('public.audit_events') is null then
    raise exception 'TRA_AUCTION_PREFLIGHT_FAILED: required production-compatible tables are missing';
  end if;
  if to_regprocedure('public.place_maximum_bid(uuid,bigint,uuid)') is not null
     or to_regprocedure('public.close_auction(uuid)') is not null then
    raise exception 'TRA_AUCTION_PREFLIGHT_FAILED: target RPC name already exists';
  end if;
end
$$;

create type public.auction_status as enum ('draft','scheduled','live','closed','cancelled');
create type public.auction_lot_status as enum ('draft','approved','scheduled','live','sold','unsold','cancelled','disputed');
create type public.bidder_status as enum ('pending','approved','suspended','rejected');
create type public.auction_submission_status as enum ('submitted','under_review','approved','rejected','scheduled','withdrawn');

create table public.auctions (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 3 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null default '',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  terms_version_id uuid not null references public.legal_document_versions(id) on delete restrict,
  status public.auction_status not null default 'draft',
  featured boolean not null default false,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint auctions_valid_window check (ends_at > starts_at)
);

create table public.bidder_eligibility (
  user_id uuid primary key references auth.users(id) on delete restrict,
  status public.bidder_status not null default 'pending',
  approved_by uuid references auth.users(id) on delete restrict,
  approved_at timestamptz,
  suspended_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bidder_approval_evidence check (
    (status = 'approved' and approved_by is not null and approved_at is not null)
    or status <> 'approved'
  )
);

create table public.auction_submissions (
  id uuid primary key default gen_random_uuid(),
  artwork_id uuid not null references public.artworks(id) on delete restrict,
  artist_id uuid not null references public.artist_profiles(id) on delete restrict,
  status public.auction_submission_status not null default 'submitted',
  artist_note text,
  admin_remarks text,
  reviewed_by uuid references auth.users(id) on delete restrict,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (artwork_id)
);

create table public.auction_lots (
  id uuid primary key default gen_random_uuid(),
  auction_id uuid not null references public.auctions(id) on delete restrict,
  artwork_id uuid not null references public.artworks(id) on delete restrict,
  lot_number integer not null check (lot_number > 0),
  status public.auction_lot_status not null default 'draft',
  opening_paise bigint not null check (opening_paise > 0),
  increment_paise bigint not null check (increment_paise > 0),
  reserve_paise bigint check (reserve_paise is null or reserve_paise >= opening_paise),
  disclose_reserve_status boolean not null default true,
  current_paise bigint,
  current_leader uuid references auth.users(id) on delete restrict,
  reserve_met boolean not null default false,
  bid_count integer not null default 0 check (bid_count >= 0),
  extension_seconds integer not null default 120 check (extension_seconds between 30 and 600),
  payment_status public.payment_status not null default 'not_requested',
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (auction_id, lot_number),
  unique (auction_id, artwork_id),
  constraint auction_lot_price_state check (
    (current_paise is null and current_leader is null and bid_count = 0)
    or (current_paise is not null and current_paise >= opening_paise and current_leader is not null and bid_count > 0)
  )
);

create unique index auction_one_open_lot_per_artwork
  on public.auction_lots(artwork_id)
  where status in ('approved','scheduled','live');
create index auctions_status_schedule_idx on public.auctions(status,starts_at,ends_at);
create index auction_lots_auction_status_idx on public.auction_lots(auction_id,status,lot_number);

create table public.auction_proxy_bids (
  lot_id uuid not null references public.auction_lots(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  maximum_paise bigint not null check (maximum_paise > 0),
  priority_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default now(),
  primary key (lot_id,user_id)
);

create table public.auction_bid_requests (
  user_id uuid not null references auth.users(id) on delete restrict,
  request_id uuid not null,
  lot_id uuid not null references public.auction_lots(id) on delete restrict,
  maximum_paise bigint not null check (maximum_paise > 0),
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id,request_id)
);

create table public.auction_bid_events (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references public.auction_lots(id) on delete restrict,
  actor_id uuid not null references auth.users(id) on delete restrict,
  displayed_paise bigint not null check (displayed_paise > 0),
  created_at timestamptz not null default now()
);
create index auction_bid_events_lot_time_idx on public.auction_bid_events(lot_id,created_at desc);

create table public.auction_watchlists (
  user_id uuid not null references auth.users(id) on delete cascade,
  lot_id uuid not null references public.auction_lots(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id,lot_id)
);

create table public.auction_disputes (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references public.auction_lots(id) on delete restrict,
  opened_by uuid not null references auth.users(id) on delete restrict,
  status text not null default 'open' check (status in ('open','under_review','resolved','rejected')),
  reason text not null check (char_length(btrim(reason)) between 10 and 2000),
  resolution text,
  resolved_by uuid references auth.users(id) on delete restrict,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.platform_settings(key,value,description)
values ('auction_real_money_bidding','false'::jsonb,'Operational kill switch. Enable only after auction terms, payments, bidder verification, and controls are approved.')
on conflict (key) do nothing;

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'auctions','bidder_eligibility','auction_submissions','auction_lots','auction_proxy_bids',
    'auction_bid_requests','auction_bid_events','auction_watchlists','auction_disputes'
  ] loop
    execute format('alter table public.%I enable row level security',table_name);
  end loop;
end
$$;

create policy auction_admin_all on public.auctions to authenticated
  using ((select public.tra_is_admin())) with check ((select public.tra_is_admin()));

create policy lot_admin_all on public.auction_lots to authenticated
  using ((select public.tra_is_admin())) with check ((select public.tra_is_admin()));
create policy lot_artist_read on public.auction_lots for select to authenticated
  using (public.tra_owns_artwork(artwork_id));

create policy bidder_own_read on public.bidder_eligibility for select to authenticated
  using (user_id = (select auth.uid()));
create policy bidder_admin_all on public.bidder_eligibility to authenticated
  using ((select public.tra_is_admin())) with check ((select public.tra_is_admin()));

create policy submission_own_read on public.auction_submissions for select to authenticated
  using (public.tra_owns_artist(artist_id));
create policy submission_artist_insert on public.auction_submissions for insert to authenticated
  with check (public.tra_owns_artist(artist_id) and public.tra_owns_artwork(artwork_id) and status='submitted');
create policy submission_admin_all on public.auction_submissions to authenticated
  using ((select public.tra_is_admin())) with check ((select public.tra_is_admin()));

create policy proxy_own_read on public.auction_proxy_bids for select to authenticated
  using (user_id = (select auth.uid()));
create policy request_own_read on public.auction_bid_requests for select to authenticated
  using (user_id = (select auth.uid()));
create policy event_admin_read on public.auction_bid_events for select to authenticated
  using ((select public.tra_is_admin()));
create policy watchlist_own_all on public.auction_watchlists to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy dispute_own_read on public.auction_disputes for select to authenticated
  using (opened_by = (select auth.uid()));
create policy dispute_own_insert on public.auction_disputes for insert to authenticated
  with check (opened_by = (select auth.uid()));
create policy dispute_admin_all on public.auction_disputes to authenticated
  using ((select public.tra_is_admin())) with check ((select public.tra_is_admin()));

create view public.public_auction_lots with (security_barrier=true) as
select l.id,l.auction_id,a.slug as auction_slug,a.title as auction_title,a.description as auction_description,
       l.lot_number,l.artwork_id,w.title as artwork_title,w.description as artwork_description,w.year_created,
       w.width_cm,w.height_cm,w.final_price_paise,w.currency,p.display_name as artist_name,
       m.secure_url as image_url,m.alt_text,a.starts_at,a.ends_at,l.opening_paise,l.increment_paise,
       l.current_paise,l.reserve_met,l.disclose_reserve_status,l.bid_count,l.status,l.payment_status,
       coalesce((select (s.value #>> '{}')::boolean from public.platform_settings s where s.key='auction_real_money_bidding'),false) as bidding_enabled
from public.auction_lots l
join public.auctions a on a.id=l.auction_id
join public.artworks w on w.id=l.artwork_id
join public.artist_profiles p on p.id=w.artist_id
left join lateral (
  select am.secure_url,am.alt_text from public.artwork_media am
  where am.artwork_id=w.id and am.is_approved
  order by am.is_primary desc,am.sort_order,am.created_at limit 1
) m on true
where a.status in ('scheduled','live','closed')
  and l.status in ('scheduled','live','sold','unsold')
  and w.status in ('published','reserved','sold')
  and p.status='approved' and p.public_visible;

create view public.public_auction_bid_history with (security_barrier=true) as
select e.id,e.lot_id,e.displayed_paise,e.created_at,
       'Bidder ' || dense_rank() over (partition by e.lot_id order by e.actor_id)::text as bidder_label
from public.auction_bid_events e
join public.auction_lots l on l.id=e.lot_id
where l.status in ('scheduled','live','sold','unsold');

revoke all on public.auctions,public.bidder_eligibility,public.auction_submissions,public.auction_lots,
  public.auction_proxy_bids,public.auction_bid_requests,public.auction_bid_events,
  public.auction_watchlists,public.auction_disputes from anon,authenticated;
grant select on public.public_auction_lots,public.public_auction_bid_history to anon,authenticated;
grant select on public.bidder_eligibility,public.auction_submissions,public.auction_proxy_bids,
  public.auction_bid_requests,public.auction_disputes to authenticated;
grant select,insert,delete on public.auction_watchlists to authenticated;
grant insert on public.auction_submissions,public.auction_disputes to authenticated;
grant select,insert,update,delete on public.auctions,public.auction_lots,public.bidder_eligibility,
  public.auction_submissions,public.auction_disputes to authenticated;
grant select on public.auction_bid_events to authenticated;

create function public.place_maximum_bid(p_auction uuid,p_maximum bigint,p_request uuid)
returns jsonb language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare
  lot public.auction_lots%rowtype;
  auction public.auctions%rowtype;
  bidder uuid := auth.uid();
  prior public.auction_bid_requests%rowtype;
  owner_user uuid;
  old_max bigint;
  top_bid record;
  second_max bigint;
  price bigint;
  moment timestamptz;
  response jsonb;
begin
  if bidder is null or not exists(select 1 from auth.users where id=bidder and email_confirmed_at is not null) then
    raise exception 'VERIFIED_ACCOUNT_REQUIRED';
  end if;
  if not coalesce((select (value #>> '{}')::boolean from public.platform_settings where key='auction_real_money_bidding'),false) then
    raise exception 'BIDDING_NOT_ACTIVATED';
  end if;
  if p_request is null or p_maximum is null or p_maximum<=0 or p_maximum>100000000000 then
    raise exception 'INVALID_BID';
  end if;
  select * into lot from public.auction_lots where id=p_auction for update;
  if not found then raise exception 'AUCTION_LOT_NOT_FOUND'; end if;
  select * into auction from public.auctions where id=lot.auction_id;
  select * into prior from public.auction_bid_requests where user_id=bidder and request_id=p_request;
  if found then
    if prior.lot_id<>p_auction or prior.maximum_paise<>p_maximum then raise exception 'REQUEST_REUSED'; end if;
    return prior.result;
  end if;
  moment:=clock_timestamp();
  if auction.status not in ('scheduled','live') or lot.status not in ('scheduled','live')
     or moment<auction.starts_at or moment>=auction.ends_at then raise exception 'AUCTION_NOT_OPEN'; end if;
  if not exists(select 1 from public.bidder_eligibility where user_id=bidder and status='approved') then
    raise exception 'BIDDER_NOT_APPROVED';
  end if;
  if not exists(select 1 from public.legal_acceptances where user_id=bidder and version_id=auction.terms_version_id) then
    raise exception 'TERMS_REQUIRED';
  end if;
  select p.user_id into owner_user from public.artworks w join public.artist_profiles p on p.id=w.artist_id
    where w.id=lot.artwork_id and w.status in ('published','reserved') and p.status='approved';
  if owner_user is null then raise exception 'ARTWORK_NOT_AVAILABLE'; end if;
  if owner_user=bidder or public.tra_is_admin() then raise exception 'CONFLICT_OF_INTEREST'; end if;
  select maximum_paise into old_max from public.auction_proxy_bids where lot_id=lot.id and user_id=bidder;
  if old_max is not null and p_maximum<=old_max then raise exception 'MAXIMUM_MUST_INCREASE'; end if;
  if p_maximum < (case when lot.current_paise is null then lot.opening_paise
                       when lot.current_leader=bidder then lot.current_paise
                       else lot.current_paise+lot.increment_paise end) then raise exception 'BELOW_MINIMUM'; end if;
  insert into public.auction_proxy_bids(lot_id,user_id,maximum_paise,priority_at)
  values(lot.id,bidder,p_maximum,moment)
  on conflict(lot_id,user_id) do update set maximum_paise=excluded.maximum_paise,
    priority_at=excluded.priority_at,updated_at=moment;
  select * into top_bid from public.auction_proxy_bids where lot_id=lot.id
    order by maximum_paise desc,priority_at,user_id limit 1;
  select maximum_paise into second_max from public.auction_proxy_bids
    where lot_id=lot.id and user_id<>top_bid.user_id order by maximum_paise desc,priority_at limit 1;
  price:=greatest(lot.opening_paise,least(top_bid.maximum_paise,coalesce(second_max+lot.increment_paise,lot.opening_paise)));
  if lot.reserve_paise is not null then
    if top_bid.maximum_paise<=lot.reserve_paise then price:=top_bid.maximum_paise;
    else price:=greatest(price,lot.reserve_paise); end if;
  end if;
  update public.auction_lots set status='live',current_leader=top_bid.user_id,current_paise=price,
    reserve_met=(reserve_paise is null or price>=reserve_paise),bid_count=bid_count+1,updated_at=moment
    where id=lot.id returning * into lot;
  if auction.ends_at-moment<=make_interval(secs=>lot.extension_seconds) then
    update public.auctions set ends_at=moment+make_interval(secs=>lot.extension_seconds),status='live',updated_at=moment
      where id=auction.id returning * into auction;
  elsif auction.status='scheduled' then
    update public.auctions set status='live',updated_at=moment where id=auction.id returning * into auction;
  end if;
  insert into public.auction_bid_events(lot_id,actor_id,displayed_paise) values(lot.id,bidder,price);
  response:=jsonb_build_object('auction_id',lot.id,'current_paise',price,'reserve_met',lot.reserve_met,
    'ends_at',auction.ends_at,'leading',lot.current_leader=bidder);
  insert into public.auction_bid_requests(user_id,request_id,lot_id,maximum_paise,result)
    values(bidder,p_request,lot.id,p_maximum,response);
  insert into public.audit_events(actor_id,action,entity_type,entity_id,new_data,metadata)
    values(bidder,'auction.bid_accepted','auction_lot',lot.id,
      jsonb_build_object('displayed_paise',price,'reserve_met',lot.reserve_met),jsonb_build_object('request_id',p_request));
  return response;
end
$$;

create function public.close_auction(p_auction uuid)
returns text language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare lot public.auction_lots%rowtype; auction public.auctions%rowtype; outcome text;
begin
  if not public.tra_is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into lot from public.auction_lots where id=p_auction for update;
  if not found then raise exception 'NOT_FOUND'; end if;
  select * into auction from public.auctions where id=lot.auction_id for update;
  if lot.status in ('sold','unsold','cancelled') then return lot.status::text; end if;
  if lot.status not in ('scheduled','live') or clock_timestamp()<auction.ends_at then raise exception 'NOT_READY_TO_CLOSE'; end if;
  outcome:=case when lot.current_leader is not null and lot.reserve_met then 'sold' else 'unsold' end;
  update public.auction_lots set status=outcome::public.auction_lot_status,closed_at=clock_timestamp(),updated_at=clock_timestamp() where id=lot.id;
  if not exists(select 1 from public.auction_lots where auction_id=auction.id and status in ('scheduled','live')) then
    update public.auctions set status='closed',updated_at=clock_timestamp() where id=auction.id;
  end if;
  insert into public.audit_events(actor_id,action,entity_type,entity_id,new_data)
    values(auth.uid(),'auction.closed','auction_lot',lot.id,jsonb_build_object('outcome',outcome,'payment_status','not_requested'));
  return outcome;
end
$$;

revoke all on function public.place_maximum_bid(uuid,bigint,uuid) from public,anon;
revoke all on function public.close_auction(uuid) from public,anon;
grant execute on function public.place_maximum_bid(uuid,bigint,uuid) to authenticated;
grant execute on function public.close_auction(uuid) to authenticated;

create trigger tra_auctions_updated_at before update on public.auctions
for each row execute function public.tra_set_updated_at();
create trigger tra_bidder_eligibility_updated_at before update on public.bidder_eligibility
for each row execute function public.tra_set_updated_at();
create trigger tra_auction_submissions_updated_at before update on public.auction_submissions
for each row execute function public.tra_set_updated_at();
create trigger tra_auction_lots_updated_at before update on public.auction_lots
for each row execute function public.tra_set_updated_at();
create trigger tra_auction_disputes_updated_at before update on public.auction_disputes
for each row execute function public.tra_set_updated_at();

commit;
