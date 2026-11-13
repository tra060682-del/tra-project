-- DESIGN DRAFT ONLY. DO NOT ADD TO supabase/migrations OR APPLY WITHOUT APPROVAL.
-- Target: development project ocstvctvmychromkcurw only.
-- Structural intent: extend existing catalogue/content/legal/audit structures and add
-- privacy-bounded notification/analytics support.

begin;
do $$ begin
  if current_setting('app.tra_phase1_target', true) is distinct from 'ocstvctvmychromkcurw:approved-development-only' then
    raise exception 'PHASE1_DRAFT_REFUSED';
  end if;
end $$;

alter table public.artist_profiles add column if not exists source_record_id text;
alter table public.artist_profiles add column if not exists reference_code text;
alter table public.artist_profiles add column if not exists practice_since_year integer;
alter table public.artist_profiles add column if not exists participation text;
alter table public.artist_profiles add column if not exists public_reference text;
create unique index if not exists artist_profiles_source_record_uidx on public.artist_profiles(source_record_id) where source_record_id is not null;

alter table public.artworks add column if not exists source_record_id text;
alter table public.artworks add column if not exists featured boolean not null default false;
alter table public.artworks add column if not exists view_count bigint not null default 0;
alter table public.artworks add column if not exists metadata jsonb not null default '{}'::jsonb;
create unique index if not exists artworks_source_record_uidx on public.artworks(source_record_id) where source_record_id is not null;
do $$ begin
  if not exists(select 1 from pg_constraint where conrelid='public.artworks'::regclass and conname='artworks_view_count_check') then
    alter table public.artworks add constraint artworks_view_count_check check(view_count>=0) not valid;
  end if;
end $$;
alter table public.artworks validate constraint artworks_view_count_check;

alter table public.taxonomies add column if not exists source_record_id text;
alter table public.taxonomies add column if not exists image_url text;
alter table public.taxonomies add column if not exists navigation_group text;
alter table public.taxonomies add column if not exists rule jsonb;
create unique index if not exists taxonomies_source_record_uidx on public.taxonomies(source_record_id) where source_record_id is not null;

-- Reviewed migration must replace the existing taxonomy_type check with the same list plus
-- artform/collection/colour. The replacement broadens values and does not rewrite rows.

create table if not exists public.artist_profile_taxonomies (
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  taxonomy_id uuid not null references public.taxonomies(id),
  created_at timestamptz not null default now(),
  primary key(artist_id,taxonomy_id)
);

create table if not exists public.artwork_taxonomies (
  artwork_id uuid not null references public.artworks(id) on delete cascade,
  taxonomy_id uuid not null references public.taxonomies(id),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key(artwork_id,taxonomy_id)
);
create index if not exists artwork_taxonomies_term_idx on public.artwork_taxonomies(taxonomy_id,artwork_id);

create table if not exists public.artwork_classification_reviews (
  id uuid primary key default gen_random_uuid(),
  artwork_id uuid not null references public.artworks(id) on delete cascade,
  source text not null,
  verified boolean not null default false,
  reviewer_id uuid references auth.users(id),
  reviewer_reference text,
  reviewed_at timestamptz,
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint classification_verified_evidence check(not verified or (reviewed_at is not null and (reviewer_id is not null or reviewer_reference is not null)))
);

alter table public.content_pages add column if not exists source_record_id text;
alter table public.content_pages add column if not exists content_type text not null default 'page';
alter table public.content_pages add column if not exists publication_status text not null default 'draft';
alter table public.content_pages add column if not exists excerpt text;
alter table public.content_pages add column if not exists category text;
alter table public.content_pages add column if not exists cover_url text;
alter table public.content_pages add column if not exists author_name text;
alter table public.content_pages add column if not exists tags text[] not null default '{}';
alter table public.content_pages add column if not exists source_citations jsonb not null default '[]'::jsonb;
alter table public.content_pages add column if not exists seo_title text;
alter table public.content_pages add column if not exists seo_description text;
alter table public.content_pages add column if not exists image_credit text;
alter table public.content_pages add column if not exists editorial_note text;
alter table public.content_pages add column if not exists reading_minutes integer;
alter table public.content_pages add column if not exists featured boolean not null default false;
alter table public.content_pages add column if not exists published_at timestamptz;
alter table public.content_pages add column if not exists view_count bigint not null default 0;
alter table public.content_pages add column if not exists metadata jsonb not null default '{}'::jsonb;
create unique index if not exists content_pages_source_record_uidx on public.content_pages(source_record_id) where source_record_id is not null;
create index if not exists content_pages_publication_idx on public.content_pages(content_type,publication_status,published_at desc);

create table if not exists public.content_relations (
  content_id uuid not null references public.content_pages(id) on delete cascade,
  relation_type text not null,
  related_id uuid not null,
  created_at timestamptz not null default now(),
  primary key(content_id,relation_type,related_id),
  constraint content_relation_type_check check(relation_type in ('artist','artwork'))
);

create table if not exists public.journal_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid not null references public.content_pages(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id,content_id)
);

alter table public.legal_documents add column if not exists audiences text[] not null default '{}';
alter table public.legal_documents add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.legal_document_versions add column if not exists title text;
alter table public.legal_document_versions add column if not exists material_change boolean not null default false;
alter table public.legal_document_versions add column if not exists change_summary text;
alter table public.legal_document_versions add column if not exists created_by_reference text;

alter table public.audit_events add column if not exists source_record_id text;
alter table public.audit_events add column if not exists actor_reference text;
alter table public.audit_events add column if not exists entity_reference text;
create unique index if not exists audit_events_source_record_uidx on public.audit_events(source_record_id) where source_record_id is not null;

create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  source_record_id text unique,
  event_name text not null,
  reference text not null default '',
  label text not null default '',
  visitor_hash text not null,
  occurred_at timestamptz not null,
  occurred_on date generated always as ((occurred_at at time zone 'UTC')::date) stored,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint analytics_visitor_hash_check check(length(visitor_hash) between 24 and 128)
);
create index if not exists analytics_events_rollup_idx on public.analytics_events(occurred_on,event_name,reference);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  title text not null,
  body text not null,
  action_url text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists notifications_unread_idx on public.notifications(user_id,created_at desc) where read_at is null;

create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  preferences jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  source_record_id text unique,
  user_id uuid references auth.users(id) on delete set null,
  recipient text not null,
  category text not null,
  subject text not null,
  body text not null,
  action_url text,
  status text not null,
  attempt_count integer not null default 0,
  last_error text,
  provider_reference text,
  claimed_at timestamptz,
  sent_at timestamptz,
  next_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notification_attempt_check check(attempt_count>=0),
  constraint notification_status_check check(status in ('queued','claimed','sent','failed','cancelled'))
);
create index if not exists notification_delivery_retry_idx on public.notification_deliveries(next_attempt_at) where status in ('queued','failed');

alter table public.artist_profile_taxonomies enable row level security;
alter table public.artwork_taxonomies enable row level security;
alter table public.artwork_classification_reviews enable row level security;
alter table public.content_relations enable row level security;
alter table public.journal_bookmarks enable row level security;
alter table public.analytics_events enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_deliveries enable row level security;

create policy artwork_taxonomies_public_read on public.artwork_taxonomies for select to anon,authenticated
using (exists(select 1 from public.artworks a where a.id=artwork_id and a.status='published'));
create policy artist_taxonomies_public_read on public.artist_profile_taxonomies for select to anon,authenticated
using (exists(select 1 from public.artist_profiles a where a.id=artist_id and a.status='approved' and a.public_visible));
create policy classification_staff on public.artwork_classification_reviews to authenticated
using (public.tra_has_permission('artworks.review')) with check (public.tra_has_permission('artworks.review'));
create policy content_relations_public_read on public.content_relations for select to anon,authenticated
using (exists(select 1 from public.content_pages p where p.id=content_id and p.is_published));
create policy journal_bookmarks_own on public.journal_bookmarks to authenticated
using (user_id=auth.uid()) with check(user_id=auth.uid());
create policy notifications_own_read on public.notifications for select to authenticated using(user_id=auth.uid());
create policy notifications_own_update on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy notification_preferences_own on public.notification_preferences to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy notification_deliveries_staff on public.notification_deliveries for select to authenticated using(public.tra_has_permission('audit.view'));
create policy analytics_staff on public.analytics_events for select to authenticated using(public.tra_has_permission('reports.view'));
do $$declare t text;begin foreach t in array array['artist_profile_taxonomies','artwork_taxonomies','artwork_classification_reviews','content_relations','journal_bookmarks','analytics_events','notifications','notification_preferences','notification_deliveries'] loop execute format('create policy phase3_active_account_gate on public.%I as restrictive for all to authenticated using (public.tra_account_is_active()) with check (public.tra_account_is_active())',t);end loop;end$$;

commit;
