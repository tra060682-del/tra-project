\set ON_ERROR_STOP on

-- Disposable production-like baseline for 202611090001_artist_auth.sql.
-- Synthetic records only. Never run against a hosted or production database.

create extension if not exists pgcrypto;
create type public.tra_role as enum ('artist','admin');
create type public.artist_status as enum (
  'draft','submitted','under_review','changes_requested','approved','rejected','suspended'
);

create table public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.user_roles(
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.tra_role not null,
  created_at timestamptz not null default now(),
  primary key(user_id,role)
);
create table public.artist_profiles(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  legal_name text,
  display_name text,
  biography text,
  artist_statement text,
  email text,
  phone text,
  city text,
  state text,
  postal_code text,
  country text not null default 'India',
  website text,
  social_links jsonb not null default '{}',
  profile_image_url text,
  status public.artist_status not null default 'draft',
  public_visible boolean not null default false,
  admin_remarks text,
  artist_remarks text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.artist_onboarding_requests(
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  status public.artist_status not null default 'draft',
  artist_note text,
  admin_remarks text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.legal_documents(
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  audience text not null default 'artist' check(audience in ('artist','public','all')),
  required_for_artist boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.legal_document_versions(
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.legal_documents(id) on delete restrict,
  version integer not null check(version>0),
  body text not null,
  content_sha256 text,
  effective_at timestamptz not null default now(),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  unique(document_id,version)
);
create table public.legal_acceptances(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  version_id uuid not null references public.legal_document_versions(id) on delete restrict,
  accepted_text_snapshot text not null,
  accepted_at timestamptz not null default now(),
  ip_address inet,
  user_agent text,
  unique(user_id,version_id)
);

create function public.tra_is_admin() returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.user_roles where user_id=(select auth.uid()) and role='admin');
$$;
create function public.tra_owns_artist(p_artist_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.artist_profiles where id=p_artist_id and user_id=(select auth.uid()));
$$;
create function public.tra_set_updated_at() returns trigger
language plpgsql set search_path='' as $$
begin new.updated_at=now(); return new; end
$$;
create function public.tra_new_user() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  insert into public.profiles(id,display_name)
  values(new.id,nullif(btrim(new.raw_user_meta_data->>'display_name'),''));
  return new;
end
$$;
create function public.register_current_user_as_artist(p_display_name text default null)
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare current_user_id uuid:=auth.uid(); confirmed_at timestamptz; metadata_name text; profile_id uuid;
begin
  if current_user_id is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  select email_confirmed_at,nullif(btrim(raw_user_meta_data->>'display_name'),'')
    into confirmed_at,metadata_name from auth.users where id=current_user_id;
  if confirmed_at is null then raise exception 'VERIFIED_EMAIL_REQUIRED'; end if;
  metadata_name:=coalesce(nullif(btrim(p_display_name),''),metadata_name);
  if metadata_name is null or char_length(metadata_name) not between 2 and 120 then
    raise exception 'VALID_DISPLAY_NAME_REQUIRED';
  end if;
  insert into public.user_roles(user_id,role) values(current_user_id,'artist') on conflict do nothing;
  insert into public.artist_profiles(user_id,display_name) values(current_user_id,metadata_name)
    on conflict(user_id) do update set display_name=public.artist_profiles.display_name returning id into profile_id;
  return profile_id;
end
$$;

create trigger on_auth_user_created_tra after insert on auth.users
for each row execute function public.tra_new_user();
create trigger set_updated_at before update on public.profiles
for each row execute function public.tra_set_updated_at();
create trigger set_updated_at before update on public.artist_profiles
for each row execute function public.tra_set_updated_at();
create trigger set_updated_at before update on public.artist_onboarding_requests
for each row execute function public.tra_set_updated_at();
create trigger set_updated_at before update on public.legal_documents
for each row execute function public.tra_set_updated_at();

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.artist_profiles enable row level security;
alter table public.artist_onboarding_requests enable row level security;
alter table public.legal_documents enable row level security;
alter table public.legal_document_versions enable row level security;
alter table public.legal_acceptances enable row level security;

create policy profile_admin_insert on public.profiles for insert to authenticated
with check((select public.tra_is_admin()));
create policy profile_read on public.profiles for select to authenticated
using(id=(select auth.uid()) or (select public.tra_is_admin()));
create policy profile_update on public.profiles for update to authenticated
using(id=(select auth.uid()) or (select public.tra_is_admin()))
with check(id=(select auth.uid()) or (select public.tra_is_admin()));
create policy admin_all on public.user_roles for all to authenticated
using((select public.tra_is_admin())) with check((select public.tra_is_admin()));
create policy role_self_read on public.user_roles for select to authenticated
using(user_id=(select auth.uid()));
create policy artist_admin_all on public.artist_profiles for all to authenticated
using((select public.tra_is_admin())) with check((select public.tra_is_admin()));
create policy artist_public_read on public.artist_profiles for select to anon,authenticated
using((status='approved' and public_visible) or (select public.tra_is_admin()) or user_id=(select auth.uid()));
create policy artist_self_insert on public.artist_profiles for insert to authenticated
with check(user_id=(select auth.uid()) and status='draft' and not public_visible and reviewed_by is null and reviewed_at is null);
create policy artist_self_update on public.artist_profiles for update to authenticated
using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy onboarding_admin on public.artist_onboarding_requests for all to authenticated
using((select public.tra_is_admin())) with check((select public.tra_is_admin()));
create policy onboarding_read on public.artist_onboarding_requests for select to authenticated
using(public.tra_owns_artist(artist_id) or (select public.tra_is_admin()));
create policy admin_all on public.legal_documents for all to authenticated
using((select public.tra_is_admin())) with check((select public.tra_is_admin()));
create policy legal_artist_read on public.legal_documents for select to authenticated using(is_active);
create policy legal_public_read on public.legal_documents for select to anon,authenticated
using(is_active and audience in ('public','all'));
create policy admin_all on public.legal_document_versions for all to authenticated
using((select public.tra_is_admin())) with check((select public.tra_is_admin()));
create policy legal_versions_artist on public.legal_document_versions for select to authenticated using(is_published);
create policy legal_versions_read on public.legal_document_versions for select to anon,authenticated
using(is_published and exists(select 1 from public.legal_documents d where d.id=document_id and d.is_active and d.audience in ('public','all')));
create policy legal_acceptance_admin on public.legal_acceptances for all to authenticated
using((select public.tra_is_admin())) with check((select public.tra_is_admin()));
create policy legal_acceptance_insert on public.legal_acceptances for insert to authenticated
with check(user_id=(select auth.uid()) and exists(select 1 from public.legal_document_versions v where v.id=version_id and v.is_published));
create policy legal_acceptance_read on public.legal_acceptances for select to authenticated
using(user_id=(select auth.uid()) or (select public.tra_is_admin()));

revoke all on public.profiles,public.user_roles,public.artist_profiles,
  public.artist_onboarding_requests,public.legal_documents,public.legal_document_versions,
  public.legal_acceptances from anon,authenticated;
grant select,insert,update,delete,truncate,references,trigger,maintain on public.profiles,
  public.user_roles,public.artist_onboarding_requests,public.legal_acceptances to authenticated;
grant select,insert,delete,truncate,references,trigger,maintain on public.artist_profiles to authenticated;
grant update(display_name,biography,artist_statement,email,phone,city,state,postal_code,country,
  website,social_links,profile_image_url) on public.artist_profiles to authenticated;
grant select,insert,update,delete,truncate,references,trigger,maintain on public.artist_profiles,
  public.legal_documents,public.legal_document_versions to anon;
grant select,insert,update,delete,truncate,references,trigger,maintain on public.legal_documents,
  public.legal_document_versions to authenticated;

revoke all on function public.register_current_user_as_artist(text) from public,anon;
grant execute on function public.register_current_user_as_artist(text) to authenticated,service_role;
revoke all on function public.tra_is_admin() from public;
grant execute on function public.tra_is_admin() to anon,authenticated,service_role;
revoke all on function public.tra_owns_artist(uuid) from public;
grant execute on function public.tra_owns_artist(uuid) to anon,authenticated,service_role;
grant execute on function public.tra_new_user(),public.tra_set_updated_at() to public,anon,authenticated,service_role;

-- Existing synthetic records used for preservation checks.
insert into auth.users(
  instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
  raw_app_meta_data,raw_user_meta_data,created_at,updated_at
) values
('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000001','authenticated','authenticated',
 'existing.artist@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{"display_name":"Existing Artist"}',now(),now()),
('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000002','authenticated','authenticated',
 'admin@example.test',crypt('Synthetic-Only-2',gen_salt('bf')),now(),'{}','{"display_name":"Synthetic Admin"}',now(),now()),
('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000003','authenticated','authenticated',
 'new.artist@example.test',crypt('Synthetic-Only-3',gen_salt('bf')),now(),'{}','{"display_name":"New Artist"}',now(),now()),
('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000004','authenticated','authenticated',
 'unverified@example.test',crypt('Synthetic-Only-4',gen_salt('bf')),null,'{}','{"display_name":"Unverified Artist"}',now(),now()),
('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000005','authenticated','authenticated',
 'other.artist@example.test',crypt('Synthetic-Only-5',gen_salt('bf')),now(),'{}','{"display_name":"Other Artist"}',now(),now());

insert into public.user_roles(user_id,role) values
  ('10000000-0000-0000-0000-000000000001','artist'),
  ('10000000-0000-0000-0000-000000000002','admin'),
  ('10000000-0000-0000-0000-000000000005','artist');
insert into public.artist_profiles(id,user_id,display_name) values
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Existing Artist'),
  ('20000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','Other Artist');
insert into public.artist_onboarding_requests(id,artist_id,artist_note) values
  ('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Preserve me'),
  ('30000000-0000-0000-0000-000000000005','20000000-0000-0000-0000-000000000005','Isolated');
insert into public.legal_documents(id,code,title,audience,required_for_artist,is_active) values
  ('40000000-0000-0000-0000-000000000001','artist-terms','Synthetic Artist Terms','artist',true,true);
insert into public.legal_document_versions(id,document_id,version,body,content_sha256,effective_at,is_published) values
  ('50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',1,
   'Synthetic terms version one','synthetic-sha256-v1',now()-interval '1 day',true);
insert into public.legal_acceptances(id,user_id,version_id,accepted_text_snapshot,user_agent) values
  ('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
   '50000000-0000-0000-0000-000000000001','Synthetic terms version one','baseline-fixture');

create table public.rehearsal_baseline(
  key text primary key,
  value text not null
);
insert into public.rehearsal_baseline(key,value) values
  ('existing_onboarding_note','Preserve me'),
  ('existing_acceptance_snapshot','Synthetic terms version one'),
  ('policy_count','20');
insert into public.rehearsal_baseline(key,value)
select 'policy_hash',md5(string_agg(
  concat_ws('|',tablename,policyname,roles::text,cmd,coalesce(qual,''),coalesce(with_check,'')),
  E'\n' order by tablename,policyname
)) from pg_policies where schemaname='public' and tablename in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances'
);
insert into public.rehearsal_baseline(key,value)
select 'table_grant_hash',md5(string_agg(
  concat_ws('|',table_name,grantee,privilege_type,is_grantable),E'\n'
  order by table_name,grantee,privilege_type
)) from information_schema.role_table_grants where table_schema='public' and table_name in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances'
);
insert into public.rehearsal_baseline(key,value)
select 'column_grant_hash',md5(coalesce(string_agg(
  concat_ws('|',c.relname,a.attname,acl.acl_item::text),E'\n'
  order by c.relname,a.attname,acl.acl_item::text
),'')) from pg_class c join pg_namespace n on n.oid=c.relnamespace
join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
cross join lateral unnest(a.attacl) acl(acl_item)
where n.nspname='public' and c.relname in (
  'profiles','user_roles','artist_profiles','artist_onboarding_requests','legal_documents','legal_document_versions','legal_acceptances'
);
