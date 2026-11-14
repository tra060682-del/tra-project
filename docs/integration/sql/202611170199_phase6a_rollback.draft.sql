-- PROPOSAL ONLY. Destructive rollback for disposable rehearsal or separately approved rollback.
begin;
do $$begin if current_setting('app.tra_phase6a_rollback',true) is distinct from 'ocstvctvmychromkcurw:approved-disposable-rollback' then raise exception 'TRA_PHASE6A_ROLLBACK_NOT_APPROVED';end if;end$$;
drop function if exists public.tra_post_ledger_transaction(uuid,text,jsonb),public.tra_verify_certificate(text),public.tra_request_refund(uuid,bigint,text),public.tra_mark_notifications_read(uuid[]),public.tra_create_artwork_reservation(uuid,timestamptz,text),public.tra_transition_offer(uuid,text,bigint,bigint,text),public.tra_create_offer(uuid,bigint,char,timestamptz,text),public.tra_change_shopping_bag(uuid,text),public.tra_clear_recently_viewed(),public.tra_record_recent_view(uuid),public.tra_toggle_wishlist(uuid);
drop table if exists public.operational_exceptions,public.private_media_access_events,public.private_media_assets,public.notification_deliveries,public.notification_preferences,public.notifications,public.certificate_events,public.shipment_events,public.settlement_events,public.intermediary_commissions,public.financial_ledger_entries,public.refund_requests,public.payment_events,public.payment_attempts,public.payment_intents cascade;
alter table public.sales drop constraint if exists sales_reservation_fk;alter table public.sales drop constraint if exists sales_offer_fk;
drop table if exists public.artwork_reservations,public.offer_events,public.offers,public.shopping_bag_items,public.shopping_bags,public.recently_viewed_artworks,public.wishlist_items cascade;
alter table public.artist_representations drop column if exists commission_rule_id,drop column if exists can_manage_shipping,drop column if exists can_negotiate_offers;
alter table public.certificates drop column if exists revocation_reason,drop column if exists revoked_at,drop column if exists verification_token_hash,drop column if exists certificate_version,drop column if exists issue_date,drop column if exists issuer_artist_id;
alter table public.shipments drop column if exists state_version;alter table public.settlements drop column if exists state_version;
alter table public.sales drop column if exists cancellation_reason,drop column if exists cancelled_at,drop column if exists state_version,drop column if exists price_snapshot,drop column if exists reservation_id,drop column if exists offer_id,drop column if exists buyer_user_id,drop column if exists order_kind,drop column if exists order_number;
alter table public.buyers drop column if exists user_id;
drop function if exists public.tra_financial_immutable();
commit;
