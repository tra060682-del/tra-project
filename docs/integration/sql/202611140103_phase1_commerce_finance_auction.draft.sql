-- DESIGN DRAFT ONLY. DO NOT ADD TO supabase/migrations OR APPLY WITHOUT APPROVAL.
-- Target: development project ocstvctvmychromkcurw only.
-- Structural intent: additive offer/payment/ledger support and extensions to existing
-- sales, certificate and hardened auction objects.

begin;
do $$ begin
  if current_setting('app.tra_phase1_target', true) is distinct from 'ocstvctvmychromkcurw:approved-development-only' then
    raise exception 'PHASE1_DRAFT_REFUSED';
  end if;
end $$;

alter table public.sales add column if not exists order_number text;
alter table public.sales add column if not exists order_kind text not null default 'artwork';
alter table public.sales add column if not exists buyer_user_id uuid references auth.users(id);
alter table public.sales add column if not exists source_record_id text;
alter table public.sales add column if not exists reservation_expires_at timestamptz;
create unique index if not exists sales_order_number_uidx on public.sales(order_number) where order_number is not null;
create unique index if not exists sales_source_record_uidx on public.sales(source_record_id) where source_record_id is not null;
create index if not exists sales_buyer_user_idx on public.sales(buyer_user_id,created_at desc) where buyer_user_id is not null;

create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  artwork_id uuid not null references public.artworks(id),
  buyer_user_id uuid not null references auth.users(id),
  status text not null default 'submitted',
  currency char(3) not null default 'INR',
  amount_paise bigint not null,
  counter_amount_paise bigint,
  message text,
  expires_at timestamptz,
  accepted_sale_id uuid references public.sales(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint offers_amount_check check(amount_paise>0 and (counter_amount_paise is null or counter_amount_paise>0)),
  constraint offers_status_check check(status in ('submitted','under_review','sent_to_artist','countered','accepted','rejected','withdrawn','expired')),
  constraint offers_acceptance_check check((status='accepted')=(accepted_sale_id is not null))
);
create index if not exists offers_buyer_idx on public.offers(buyer_user_id,created_at desc);
create index if not exists offers_artwork_open_idx on public.offers(artwork_id,status) where status in ('submitted','under_review','sent_to_artist','countered');

create table if not exists public.offer_events (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.offers(id) on delete cascade,
  actor_id uuid not null references auth.users(id),
  action text not null,
  amount_paise bigint,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint offer_event_amount_check check(amount_paise is null or amount_paise>0)
);
create index if not exists offer_events_offer_idx on public.offer_events(offer_id,created_at);

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  provider_event_id text not null,
  provider_payment_id text,
  sale_id uuid references public.sales(id),
  event_type text not null,
  amount_paise bigint,
  currency char(3),
  signature_verified boolean not null default false,
  payload_sha256 text not null,
  payload jsonb not null,
  processed_at timestamptz,
  processing_error text,
  created_at timestamptz not null default now(),
  unique(provider,provider_event_id),
  constraint payment_event_amount_check check(amount_paise is null or amount_paise>=0),
  constraint payment_event_currency_check check(currency is null or currency ~ '^[A-Z]{3}$')
);
create index if not exists payment_events_sale_idx on public.payment_events(sale_id,created_at);

create table if not exists public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id),
  payment_event_id uuid references public.payment_events(id),
  entry_type text not null,
  account text not null,
  direction text not null,
  amount_paise bigint not null,
  currency char(3) not null default 'INR',
  reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint ledger_amount_check check(amount_paise>0),
  constraint ledger_direction_check check(direction in ('debit','credit')),
  constraint ledger_currency_check check(currency ~ '^[A-Z]{3}$')
);
create index if not exists ledger_entries_sale_idx on public.ledger_entries(sale_id,created_at);
create unique index if not exists ledger_entries_event_account_uidx on public.ledger_entries(payment_event_id,entry_type,account,direction) where payment_event_id is not null;

create or replace function public.tra_ledger_immutable()
returns trigger language plpgsql set search_path=public,pg_temp
as $$ begin raise exception 'LEDGER_IMMUTABLE'; end $$;
drop trigger if exists tra_ledger_immutable on public.ledger_entries;
create trigger tra_ledger_immutable before update or delete on public.ledger_entries
for each row execute function public.tra_ledger_immutable();

alter table public.certificates add column if not exists source_record_id text;
alter table public.certificates add column if not exists public_token_hash text;
alter table public.certificates add column if not exists snapshot jsonb not null default '{}'::jsonb;
create unique index if not exists certificates_source_record_uidx on public.certificates(source_record_id) where source_record_id is not null;
create unique index if not exists certificates_token_hash_uidx on public.certificates(public_token_hash) where public_token_hash is not null;

create table if not exists public.bidder_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email_snapshot text,
  phone text,
  city text,
  alias text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bidder_alias_check check(alias ~ '^[A-Za-z0-9_-]{3,40}$')
);

alter table public.auctions add column if not exists paused boolean not null default false;
alter table public.auction_lots add column if not exists source_record_id text;
alter table public.auction_lots add column if not exists state_version bigint not null default 1;
alter table public.auction_lots add column if not exists extension_count integer not null default 0;
alter table public.auction_lots add column if not exists estimate_low_paise bigint;
alter table public.auction_lots add column if not exists estimate_high_paise bigint;
alter table public.auction_lots add column if not exists buyer_premium_rate_snapshot numeric(7,4);
alter table public.auction_lots add column if not exists metadata jsonb not null default '{}'::jsonb;
create unique index if not exists auction_lots_source_record_uidx on public.auction_lots(source_record_id) where source_record_id is not null;
do $$ begin
  if not exists(select 1 from pg_constraint where conrelid='public.auction_lots'::regclass and conname='auction_lot_estimate_check') then
    alter table public.auction_lots add constraint auction_lot_estimate_check check(
      (estimate_low_paise is null or estimate_low_paise>=0) and
      (estimate_high_paise is null or estimate_high_paise>=coalesce(estimate_low_paise,0)) and
      extension_count>=0 and state_version>0
    ) not valid;
  end if;
end $$;
alter table public.auction_lots validate constraint auction_lot_estimate_check;

alter table public.offers enable row level security;
alter table public.offer_events enable row level security;
alter table public.payment_events enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.bidder_profiles enable row level security;

create policy offers_buyer_read on public.offers for select to authenticated using(buyer_user_id=auth.uid());
create policy offers_staff_read on public.offers for select to authenticated using(public.tra_has_permission('offers.manage'));
create policy offers_artist_read on public.offers for select to authenticated using(
  exists(select 1 from public.artworks w where w.id=artwork_id and public.tra_owns_artist(w.artist_id))
);
create policy offer_events_party_read on public.offer_events for select to authenticated using(
  exists(select 1 from public.offers o join public.artworks w on w.id=o.artwork_id
    where o.id=offer_id and (o.buyer_user_id=auth.uid() or public.tra_owns_artist(w.artist_id) or public.tra_has_permission('offers.manage')))
);
create policy payment_events_finance_read on public.payment_events for select to authenticated using(public.tra_has_permission('payments.manage'));
create policy ledger_finance_read on public.ledger_entries for select to authenticated using(public.tra_has_permission('payments.manage') or public.tra_has_permission('settlements.manage'));
create policy bidder_profile_own_read on public.bidder_profiles for select to authenticated using(user_id=auth.uid() or public.tra_has_permission('bidders.manage'));
create policy bidder_profile_own_insert on public.bidder_profiles for insert to authenticated with check(user_id=auth.uid());
create policy bidder_profile_own_update on public.bidder_profiles for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
do $$declare t text;begin foreach t in array array['offers','offer_events','payment_events','ledger_entries','bidder_profiles'] loop execute format('create policy phase3_active_account_gate on public.%I as restrictive for all to authenticated using (public.tra_account_is_active()) with check (public.tra_account_is_active())',t);end loop;end$$;

revoke all on public.offers,public.offer_events,public.payment_events,public.ledger_entries,public.bidder_profiles from anon,authenticated;
grant select on public.offers,public.offer_events,public.payment_events,public.ledger_entries to authenticated;
grant select,insert,update on public.bidder_profiles to authenticated;

create or replace function public.submit_offer(p_artwork uuid,p_amount_paise bigint,p_message text default null)
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp
as $$
declare v_user uuid:=auth.uid(); v_id uuid;
begin
  if v_user is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not public.tra_account_is_active(v_user) then raise exception 'ACCOUNT_INACTIVE'; end if;
  if p_amount_paise<=0 then raise exception 'INVALID_AMOUNT'; end if;
  perform pg_advisory_xact_lock(hashtextextended('offer:'||p_artwork::text||':'||v_user::text,0));
  if not exists(select 1 from public.artworks where id=p_artwork and status='published') then raise exception 'ARTWORK_NOT_AVAILABLE'; end if;
  if exists(select 1 from public.artworks where id=p_artwork and public.tra_owns_artist(artist_id)) then raise exception 'SELF_DEALING_FORBIDDEN'; end if;
  insert into public.offers(artwork_id,buyer_user_id,amount_paise,message) values(p_artwork,v_user,p_amount_paise,nullif(btrim(p_message),'')) returning id into v_id;
  insert into public.offer_events(offer_id,actor_id,action,amount_paise) values(v_id,v_user,'submitted',p_amount_paise);
  return v_id;
end $$;

revoke all on function public.submit_offer(uuid,bigint,text) from public;
grant execute on function public.submit_offer(uuid,bigint,text) to authenticated;

-- Reuse the Phase 3 account-status guard on additive commercial tables. Trusted
-- service operations have no auth.uid(); authenticated users must remain active.
do $$declare t text;begin foreach t in array array['offers','offer_events','payment_events','ledger_entries'] loop execute format('drop trigger if exists tra_active_actor_guard on public.%I',t);execute format('create trigger tra_active_actor_guard before insert or update or delete on public.%I for each row execute function public.tra_require_active_actor()',t);end loop;end$$;

-- Payment event ingestion and offer acceptance require provider/state-specific reviewed RPCs.
-- No authenticated or anon INSERT/UPDATE/DELETE policies are intentionally created for
-- payment_events or ledger_entries; only a trusted server route may call their RPCs.

commit;
