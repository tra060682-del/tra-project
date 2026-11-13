-- DESTRUCTIVE ROLLBACK DESIGN DRAFT. NEVER RUN WITHOUT A VERIFIED BACKUP AND APPROVAL.
-- This removes only Phase 1 additive objects/columns. Existing pre-Phase-1 tables and data stay.
-- PostgreSQL enum values cannot be safely removed; super_admin/finance/advisor are retained.

begin;
do $$ begin
  if current_setting('app.tra_phase1_rollback', true) is distinct from 'ocstvctvmychromkcurw:approved-development-rollback' then
    raise exception 'PHASE1_ROLLBACK_REFUSED';
  end if;
end $$;

drop function if exists public.submit_offer(uuid,bigint,text);

drop table if exists public.ledger_entries;
drop function if exists public.tra_ledger_immutable();
drop table if exists public.payment_events;
drop table if exists public.offer_events;
drop table if exists public.offers;
drop table if exists public.bidder_profiles;
drop table if exists public.notification_deliveries;
drop table if exists public.notification_preferences;
drop table if exists public.notifications;
drop table if exists public.analytics_events;
drop table if exists public.journal_bookmarks;
drop table if exists public.content_relations;
drop table if exists public.artwork_classification_reviews;
drop table if exists public.artwork_taxonomies;
drop table if exists public.artist_profile_taxonomies;

alter table public.auction_lots
  drop column if exists source_record_id,
  drop column if exists state_version,
  drop column if exists extension_count,
  drop column if exists estimate_low_paise,
  drop column if exists estimate_high_paise,
  drop column if exists buyer_premium_rate_snapshot,
  drop column if exists metadata;
alter table public.auctions drop column if exists paused;
alter table public.certificates
  drop column if exists source_record_id,
  drop column if exists public_token_hash,
  drop column if exists snapshot;
alter table public.sales
  drop column if exists order_number,
  drop column if exists order_kind,
  drop column if exists buyer_user_id,
  drop column if exists source_record_id,
  drop column if exists reservation_expires_at;
alter table public.audit_events
  drop column if exists source_record_id,
  drop column if exists actor_reference,
  drop column if exists entity_reference;
alter table public.legal_document_versions
  drop column if exists title,
  drop column if exists material_change,
  drop column if exists change_summary,
  drop column if exists created_by_reference;
alter table public.legal_documents
  drop column if exists audiences,
  drop column if exists metadata;
alter table public.content_pages
  drop column if exists source_record_id,
  drop column if exists content_type,
  drop column if exists publication_status,
  drop column if exists excerpt,
  drop column if exists category,
  drop column if exists cover_url,
  drop column if exists author_name,
  drop column if exists tags,
  drop column if exists source_citations,
  drop column if exists seo_title,
  drop column if exists seo_description,
  drop column if exists image_credit,
  drop column if exists editorial_note,
  drop column if exists reading_minutes,
  drop column if exists featured,
  drop column if exists published_at,
  drop column if exists view_count,
  drop column if exists metadata;
alter table public.taxonomies
  drop column if exists source_record_id,
  drop column if exists image_url,
  drop column if exists navigation_group,
  drop column if exists rule;
alter table public.artworks
  drop column if exists source_record_id,
  drop column if exists featured,
  drop column if exists view_count,
  drop column if exists metadata;
alter table public.artist_profiles
  drop column if exists source_record_id,
  drop column if exists reference_code,
  drop column if exists practice_since_year,
  drop column if exists participation,
  drop column if exists public_reference;
alter table public.profiles
  drop column if exists last_seen_at,
  drop column if exists metadata;

-- Phase 3 owns account_status, role_permissions, user_permission_overrides and
-- the tra_* authorization helpers. Its rollback runs after this rollback.

-- The reviewed rollback must restore the exact pre-migration taxonomy_type constraint hash
-- if the approved forward migration broadened its value list.
-- No emergent_staging object is dropped or altered by rollback.

commit;
