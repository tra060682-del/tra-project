-- Auction evidence hardening. Additive follow-up to 202611120001.
begin;
revoke update,delete on public.auctions,public.auction_lots,public.bidder_eligibility,public.auction_submissions,public.auction_disputes from authenticated;
grant update(title,slug,description,starts_at,ends_at,terms_version_id,status,featured) on public.auctions to authenticated;
grant update(status,opening_paise,increment_paise,reserve_paise,disclose_reserve_status,payment_status) on public.auction_lots to authenticated;
grant update(status,approved_by,approved_at,suspended_reason) on public.bidder_eligibility to authenticated;
grant update(status,admin_remarks,reviewed_by,reviewed_at) on public.auction_submissions to authenticated;
grant update(status,resolution,resolved_by,resolved_at) on public.auction_disputes to authenticated;
create function public.tra_guard_terminal_auction() returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
  if new.status is distinct from old.status and new.status in ('live','closed') and current_user<>'postgres' then raise exception 'AUCTION_ENGINE_TRANSITION_REQUIRED'; end if;
  if old.status in ('closed','cancelled') and (new.title is distinct from old.title or new.slug is distinct from old.slug or new.description is distinct from old.description or new.starts_at is distinct from old.starts_at or new.ends_at is distinct from old.ends_at or new.terms_version_id is distinct from old.terms_version_id or new.featured is distinct from old.featured or new.status is distinct from old.status) then raise exception 'TERMINAL_AUCTION_IMMUTABLE'; end if;
  return new;
end$$;
create function public.tra_guard_terminal_auction_lot() returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
  if new.status is distinct from old.status and new.status in ('live','sold','unsold') and current_user<>'postgres' then raise exception 'AUCTION_ENGINE_TRANSITION_REQUIRED'; end if;
  if old.status in ('sold','unsold','cancelled') and (new.auction_id is distinct from old.auction_id or new.artwork_id is distinct from old.artwork_id or new.lot_number is distinct from old.lot_number or new.opening_paise is distinct from old.opening_paise or new.increment_paise is distinct from old.increment_paise or new.reserve_paise is distinct from old.reserve_paise or new.disclose_reserve_status is distinct from old.disclose_reserve_status or new.current_paise is distinct from old.current_paise or new.current_leader is distinct from old.current_leader or new.reserve_met is distinct from old.reserve_met or new.bid_count is distinct from old.bid_count or new.extension_seconds is distinct from old.extension_seconds or new.closed_at is distinct from old.closed_at or (new.status is distinct from old.status and not (old.status='sold' and new.status='disputed'))) then raise exception 'TERMINAL_AUCTION_LOT_IMMUTABLE'; end if;
  return new;
end$$;
revoke all on function public.tra_guard_terminal_auction() from public,anon,authenticated;
revoke all on function public.tra_guard_terminal_auction_lot() from public,anon,authenticated;
create trigger tra_guard_terminal_auction before update on public.auctions for each row execute function public.tra_guard_terminal_auction();
create trigger tra_guard_terminal_auction_lot before update on public.auction_lots for each row execute function public.tra_guard_terminal_auction_lot();
commit;
