-- Foundation migration. Apply to a fresh Supabase project. Currency is integer paise.
create extension if not exists pgcrypto;
create type public.staff_role as enum ('super_admin','admin','intermediary','artist','curator');
create table public.user_roles(user_id uuid references auth.users on delete restrict,role public.staff_role not null,primary key(user_id,role));
create function public.has_role(roles public.staff_role[]) returns boolean language sql stable security definer set search_path=public,pg_temp as $$select exists(select 1 from public.user_roles where user_id=auth.uid() and role=any(roles))$$;
revoke all on function public.has_role(public.staff_role[]) from public;
grant execute on function public.has_role(public.staff_role[]) to authenticated;
alter table public.user_roles enable row level security;
create policy own_roles on public.user_roles for select to authenticated using(user_id=auth.uid() or public.has_role(array['super_admin']::public.staff_role[]));
-- Role assignment is a service-side/bootstrap operation until audited super-admin tooling exists.
create table public.artist_profiles(id uuid primary key default gen_random_uuid(),user_id uuid unique not null references auth.users,display_name text not null,approved boolean not null default false,created_at timestamptz not null default now());
create table public.artist_intermediaries(id uuid primary key default gen_random_uuid(),artist_id uuid not null references public.artist_profiles,intermediary_user_id uuid not null references auth.users,starts_at timestamptz not null default now(),ends_at timestamptz,can_submit boolean not null default false,can_view_settlement boolean not null default false,terms_snapshot jsonb not null default '{}',created_by uuid references auth.users,check(ends_at is null or ends_at>starts_at));
create table public.artworks(id uuid primary key default gen_random_uuid(),artist_id uuid not null references public.artist_profiles,title text not null,slug text unique not null,description text not null default '',status text not null default 'draft' check(status in ('draft','review','approved','published','reserved','sold','archived')),listing_price_paise bigint check(listing_price_paise>0),cloudinary_public_id text,created_at timestamptz not null default now());
create table public.auction_terms(id uuid primary key default gen_random_uuid(),version text unique not null,content text not null,content_hash text not null,active boolean not null default false);
create unique index one_active_auction_terms on public.auction_terms(active) where active;
create table public.auction_acceptances(user_id uuid references auth.users,terms_id uuid references public.auction_terms,accepted_at timestamptz not null default now(),primary key(user_id,terms_id));
create table public.auctions(id uuid primary key default gen_random_uuid(),artwork_id uuid not null references public.artworks,terms_id uuid not null references public.auction_terms,starts_at timestamptz not null,ends_at timestamptz not null,opening_paise bigint not null check(opening_paise>0),increment_paise bigint not null check(increment_paise>0),reserve_paise bigint check(reserve_paise>=opening_paise),current_paise bigint,current_leader uuid references auth.users,reserve_met boolean not null default false,bid_count integer not null default 0,status text not null default 'draft' check(status in ('draft','scheduled','live','sold','unsold','cancelled')),extension_seconds integer not null default 120 check(extension_seconds between 30 and 600),check(ends_at>starts_at));
create unique index one_active_auction_per_work on public.auctions(artwork_id) where status in ('scheduled','live');
create table public.proxy_bids(auction_id uuid references public.auctions,user_id uuid references auth.users,maximum_paise bigint not null check(maximum_paise>0),priority_at timestamptz not null default clock_timestamp(),primary key(auction_id,user_id));
create table public.bid_requests(user_id uuid references auth.users,request_id uuid,auction_id uuid references public.auctions,maximum_paise bigint not null,result jsonb not null,created_at timestamptz not null default now(),primary key(user_id,request_id));
create table public.bid_events(id uuid primary key default gen_random_uuid(),auction_id uuid references public.auctions,actor_id uuid references auth.users,displayed_paise bigint not null,created_at timestamptz not null default now());
create table public.watchlists(user_id uuid references auth.users,auction_id uuid references public.auctions,created_at timestamptz not null default now(),primary key(user_id,auction_id));
create table public.sales(id uuid primary key default gen_random_uuid(),auction_id uuid unique references public.auctions,artwork_id uuid not null references public.artworks,buyer_id uuid not null references auth.users,agreed_paise bigint not null check(agreed_paise>0),commercial_snapshot jsonb not null, payment_status text not null default 'not_requested',created_at timestamptz not null default now());
create unique index one_sale_per_work on public.sales(artwork_id);
create table public.audit_events(id uuid primary key default gen_random_uuid(),actor_id uuid references auth.users,action text not null,entity_id uuid not null,metadata jsonb not null default '{}',created_at timestamptz not null default now());
-- No raw operational table is public. Explicit safe projections below.
do $$declare t text;begin foreach t in array array['artist_profiles','artist_intermediaries','artworks','auction_terms','auction_acceptances','auctions','proxy_bids','bid_requests','bid_events','watchlists','sales','audit_events'] loop execute format('alter table public.%I enable row level security',t);execute format('create policy staff_read on public.%I for select to authenticated using(public.has_role(array[''super_admin'',''admin'']::public.staff_role[]))',t);end loop;end$$;
create policy own_artist on public.artist_profiles for select to authenticated using(user_id=auth.uid());
create policy own_associations on public.artist_intermediaries for select to authenticated using(intermediary_user_id=auth.uid() or exists(select 1 from public.artist_profiles p where p.id=artist_id and p.user_id=auth.uid()));
create policy own_artwork on public.artworks for select to authenticated using(exists(select 1 from public.artist_profiles p where p.id=artist_id and p.user_id=auth.uid()));
create policy public_terms on public.auction_terms for select to anon,authenticated using(active);
create policy own_acceptance_read on public.auction_acceptances for select to authenticated using(user_id=auth.uid());
create policy own_acceptance_insert on public.auction_acceptances for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.auction_terms t where t.id=terms_id and t.active));
create policy own_proxy on public.proxy_bids for select to authenticated using(user_id=auth.uid());
create policy own_requests on public.bid_requests for select to authenticated using(user_id=auth.uid());
create policy own_sale on public.sales for select to authenticated using(buyer_id=auth.uid());
create policy own_watchlist on public.watchlists for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
-- Explicit projection deliberately excludes reserve amount, bidder identities and maximums.
create view public.public_artworks with (security_barrier=true) as select a.id,a.slug,a.title,a.description,a.listing_price_paise,a.cloudinary_public_id,p.display_name from public.artworks a join public.artist_profiles p on p.id=a.artist_id where a.status='published' and p.approved;
create view public.public_auctions with (security_barrier=true) as select a.id,a.artwork_id,w.title,a.starts_at,a.ends_at,a.opening_paise,a.increment_paise,a.current_paise,a.reserve_met,a.bid_count,a.status from public.auctions a join public.artworks w on w.id=a.artwork_id join public.artist_profiles p on p.id=w.artist_id where a.status in ('scheduled','live','sold','unsold') and w.status in ('published','reserved','sold') and p.approved;
grant select on public.public_artworks,public.public_auctions to anon,authenticated;
-- Avoid Supabase default privileges granting new tables unrestricted mutations.
revoke all on public.user_roles,public.artist_profiles,public.artist_intermediaries,public.artworks,public.auction_terms,public.auction_acceptances,public.auctions,public.proxy_bids,public.bid_requests,public.bid_events,public.watchlists,public.sales,public.audit_events from anon,authenticated;
grant select on all tables in schema public to authenticated;
grant select on public.auction_terms to anon;
grant insert on public.auction_acceptances to authenticated;
grant insert,delete on public.watchlists to authenticated;
create function public.place_maximum_bid(p_auction uuid,p_maximum bigint,p_request uuid) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.auctions%rowtype;u uuid:=auth.uid();prior public.bid_requests%rowtype;owner_id uuid;artist uuid;top_bid record;second_max bigint;old_max bigint;price bigint;moment timestamptz;result jsonb;
begin
 if u is null or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null) then raise exception 'VERIFIED_ACCOUNT_REQUIRED';end if;
 if p_request is null or p_maximum is null or p_maximum<=0 or p_maximum>100000000000 then raise exception 'INVALID_BID';end if;
 -- Serialize all requests for a lot; check time only after acquiring the lock.
 select * into a from public.auctions where id=p_auction for update;
 if not found then raise exception 'AUCTION_NOT_FOUND';end if;
 select * into prior from public.bid_requests where user_id=u and request_id=p_request;
 if found then if prior.auction_id<>p_auction or prior.maximum_paise<>p_maximum then raise exception 'REQUEST_REUSED';end if;return prior.result;end if;
 moment:=clock_timestamp();
 if a.status not in ('scheduled','live') or moment<a.starts_at or moment>=a.ends_at then raise exception 'AUCTION_NOT_OPEN';end if;
 if not exists(select 1 from public.auction_acceptances where user_id=u and terms_id=a.terms_id) then raise exception 'TERMS_REQUIRED';end if;
 select p.user_id,p.id into owner_id,artist from public.artworks w join public.artist_profiles p on p.id=w.artist_id where w.id=a.artwork_id and w.status='published' and p.approved;
 if owner_id is null then raise exception 'ARTWORK_NOT_AVAILABLE';end if;
 if owner_id=u or public.has_role(array['super_admin','admin','curator']::public.staff_role[]) or exists(select 1 from public.artist_intermediaries where artist_id=artist and intermediary_user_id=u and starts_at<=moment and (ends_at is null or ends_at>moment)) then raise exception 'CONFLICT_OF_INTEREST';end if;
 select maximum_paise into old_max from public.proxy_bids where auction_id=a.id and user_id=u;
 if old_max is not null and p_maximum<=old_max then raise exception 'MAXIMUM_MUST_INCREASE';end if;
 if p_maximum<case when a.current_paise is null then a.opening_paise when a.current_leader=u then a.current_paise else a.current_paise+a.increment_paise end then raise exception 'BELOW_MINIMUM';end if;
 insert into public.proxy_bids(auction_id,user_id,maximum_paise,priority_at) values(a.id,u,p_maximum,moment) on conflict(auction_id,user_id) do update set maximum_paise=excluded.maximum_paise,priority_at=excluded.priority_at;
 select * into top_bid from public.proxy_bids where auction_id=a.id order by maximum_paise desc,priority_at,user_id limit 1;
 select maximum_paise into second_max from public.proxy_bids where auction_id=a.id and user_id<>top_bid.user_id order by maximum_paise desc,priority_at limit 1;
 price:=greatest(a.opening_paise,least(top_bid.maximum_paise,coalesce(second_max+a.increment_paise,a.opening_paise)));
 if a.reserve_paise is not null then if top_bid.maximum_paise<=a.reserve_paise then price:=top_bid.maximum_paise;else price:=greatest(price,a.reserve_paise);end if;end if;
 update public.auctions set status='live',current_leader=top_bid.user_id,current_paise=price,reserve_met=(a.reserve_paise is null or price>=a.reserve_paise),bid_count=bid_count+1,ends_at=case when a.ends_at-moment<=make_interval(secs=>a.extension_seconds) then moment+make_interval(secs=>a.extension_seconds) else a.ends_at end where id=a.id returning * into a;
 insert into public.bid_events(auction_id,actor_id,displayed_paise) values(a.id,u,price);
 insert into public.audit_events(actor_id,action,entity_id,metadata) values(u,'auction.bid_accepted',a.id,jsonb_build_object('request_id',p_request,'displayed_paise',price));
 result:=jsonb_build_object('auction_id',a.id,'current_paise',price,'reserve_met',a.reserve_met,'ends_at',a.ends_at,'leading',a.current_leader=u);
 insert into public.bid_requests(user_id,request_id,auction_id,maximum_paise,result) values(u,p_request,a.id,p_maximum,result);
 return result;
end$$;
revoke all on function public.place_maximum_bid(uuid,bigint,uuid) from public;
grant execute on function public.place_maximum_bid(uuid,bigint,uuid) to authenticated;
create function public.close_auction(p_auction uuid) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.auctions%rowtype;associations jsonb;
begin
 if not public.has_role(array['super_admin','admin']::public.staff_role[]) then raise exception 'FORBIDDEN';end if;
 select * into a from public.auctions where id=p_auction for update;
 if not found then raise exception 'NOT_FOUND';end if;
 if a.status in ('sold','unsold','cancelled') then return a.status;end if;
 if a.status not in ('scheduled','live') or clock_timestamp()<a.ends_at then raise exception 'NOT_READY_TO_CLOSE';end if;
 if a.current_leader is not null and a.reserve_met then
 select coalesce(jsonb_agg(jsonb_build_object('intermediary_user_id',i.intermediary_user_id,'terms',i.terms_snapshot)),'[]') into associations from public.artist_intermediaries i join public.artworks w on w.artist_id=i.artist_id where w.id=a.artwork_id and i.starts_at<=now() and (i.ends_at is null or i.ends_at>now());
 insert into public.sales(auction_id,artwork_id,buyer_id,agreed_paise,commercial_snapshot) values(a.id,a.artwork_id,a.current_leader,a.current_paise,jsonb_build_object('hammer_paise',a.current_paise,'intermediaries',associations,'financial_review_required',true));
 update public.artworks set status='reserved' where id=a.artwork_id;
 update public.auctions set status='sold' where id=a.id;
 else update public.auctions set status='unsold' where id=a.id;end if;
 insert into public.audit_events(actor_id,action,entity_id) values(auth.uid(),'auction.closed',a.id);
 return case when a.current_leader is not null and a.reserve_met then 'sold' else 'unsold' end;
end$$;
revoke all on function public.close_auction(uuid) from public;
grant execute on function public.close_auction(uuid) to authenticated;
-- Even operational administrators do not need bidder ceilings.
drop policy staff_read on public.proxy_bids;
drop policy staff_read on public.bid_requests;
revoke insert on public.auction_acceptances from authenticated;
grant insert(user_id,terms_id) on public.auction_acceptances to authenticated;
