-- READ-ONLY VERIFICATION DRAFT. Run only after an approved development migration.
-- Expected result: every issue_count is zero. This file performs no writes.

with latest_import as (
  select counts from emergent_staging.import_runs order by id desc limit 1
)
select 'target_roles_missing' as check_name, count(*) as issue_count
from (values ('super_admin'),('finance'),('advisor')) expected(role)
where not exists(select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typnamespace='public'::regnamespace and t.typname='tra_role' and e.enumlabel=expected.role)
union all
select 'required_tables_missing', count(*) from (values
 ('role_permissions'),('user_permission_overrides'),('artist_profile_taxonomies'),
 ('artwork_taxonomies'),('artwork_classification_reviews'),('content_relations'),
 ('journal_bookmarks'),('analytics_events'),('notifications'),('notification_preferences'),
 ('notification_deliveries'),('offers'),('offer_events'),('payment_events'),
 ('ledger_entries'),('bidder_profiles')
) expected(name) where to_regclass('public.'||expected.name) is null
union all
select 'rls_disabled', count(*) from pg_class c where c.oid=any(array[
 'public.role_permissions'::regclass,'public.user_permission_overrides'::regclass,
 'public.artwork_taxonomies'::regclass,'public.artwork_classification_reviews'::regclass,
 'public.content_relations'::regclass,'public.journal_bookmarks'::regclass,
 'public.analytics_events'::regclass,'public.notifications'::regclass,
 'public.notification_preferences'::regclass,'public.notification_deliveries'::regclass,
 'public.offers'::regclass,'public.offer_events'::regclass,'public.payment_events'::regclass,
 'public.ledger_entries'::regclass,'public.bidder_profiles'::regclass]) and not c.relrowsecurity
union all
select 'staging_api_grants', count(*) from information_schema.role_table_grants
where table_schema='emergent_staging' and grantee in ('anon','authenticated','PUBLIC')
union all
select 'staging_record_count_changed', abs((
 select sum((entry.value)::text::integer) from latest_import, lateral jsonb_each(latest_import.counts) entry
) - 400)
union all
select 'staging_collection_count_changed', abs((
 select count(*) from latest_import, lateral jsonb_object_keys(counts)
) - 15)
union all
select 'negative_offer_amount', count(*) from public.offers where amount_paise<=0 or coalesce(counter_amount_paise,1)<=0
union all
select 'unsigned_processed_payment', count(*) from public.payment_events where processed_at is not null and not signature_verified
union all
select 'ledger_non_positive', count(*) from public.ledger_entries where amount_paise<=0
union all
select 'protected_permission_below_super_admin', count(*)
from public.role_permissions
where permission in ('roles.manage','settings.manage','integrations.manage') and role::text<>'super_admin'
union all
select 'published_content_without_timestamp', count(*) from public.content_pages
where publication_status='published' and published_at is null
union all
select 'orphan_artwork_taxonomy', count(*) from public.artwork_taxonomies x
where not exists(select 1 from public.artworks a where a.id=x.artwork_id)
   or not exists(select 1 from public.taxonomies t where t.id=x.taxonomy_id);

-- Inventory preservation checks captured before apply must separately compare hashes for:
-- existing tables/columns, constraints, policies, functions, grants, triggers and row counts.
-- New additive columns are allow-listed; no existing column/type/table may disappear or narrow.
