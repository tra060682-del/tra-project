-- tRA Phase 1 marketplace workflows. Additive and development-first.
begin;
do $$begin
 if to_regclass('public.artist_profiles') is null or to_regclass('public.artworks') is null
    or to_regclass('public.audit_events') is null or to_regprocedure('public.tra_is_admin()') is null
    then raise exception 'TRA_PHASE1_PREFLIGHT_FAILED'; end if;
end$$;

create type public.intermediary_status as enum ('draft','submitted','under_review','changes_requested','approved','rejected','suspended');
create type public.representation_status as enum ('pending_artist','pending_admin','approved','rejected','ended');

create table public.intermediary_profiles(
 id uuid primary key default gen_random_uuid(),user_id uuid not null unique references auth.users(id) on delete cascade,
 display_name text not null,organisation_name text,biography text,email text,phone text,city text,state text,country text not null default 'India',website text,
 status public.intermediary_status not null default 'draft',admin_remarks text,submitted_at timestamptz,reviewed_at timestamptz,reviewed_by uuid references auth.users(id) on delete restrict,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 constraint intermediary_display_name_check check(char_length(btrim(display_name)) between 2 and 120)
);
create table public.artist_representations(
 id uuid primary key default gen_random_uuid(),artist_id uuid not null references public.artist_profiles(id) on delete restrict,
 intermediary_id uuid not null references public.intermediary_profiles(id) on delete restrict,status public.representation_status not null default 'pending_artist',
 can_submit_artwork boolean not null default false,can_view_fulfilment boolean not null default false,can_manage_profile boolean not null default false,
 request_note text,artist_responded_at timestamptz,admin_remarks text,reviewed_at timestamptz,reviewed_by uuid references auth.users(id) on delete restrict,
 starts_at timestamptz,ends_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 constraint representation_dates_check check(ends_at is null or starts_at is null or ends_at>starts_at)
);
create unique index artist_representation_open_uq on public.artist_representations(artist_id,intermediary_id) where status in ('pending_artist','pending_admin','approved');
create index intermediary_profiles_status_idx on public.intermediary_profiles(status,created_at desc);
create index artist_representations_artist_idx on public.artist_representations(artist_id,status);

create function public.tra_is_curator_or_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.user_roles where user_id=(select auth.uid()) and role::text in ('admin','curator'))
$$;
create function public.tra_owns_intermediary(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.intermediary_profiles where id=p_id and user_id=(select auth.uid()))
$$;
revoke all on function public.tra_is_curator_or_admin(),public.tra_owns_intermediary(uuid) from public;
grant execute on function public.tra_is_curator_or_admin(),public.tra_owns_intermediary(uuid) to authenticated,service_role;

alter table public.intermediary_profiles enable row level security;
alter table public.artist_representations enable row level security;
create policy intermediary_owner_read on public.intermediary_profiles for select to authenticated using(user_id=(select auth.uid()));
create policy intermediary_owner_update on public.intermediary_profiles for update to authenticated using(user_id=(select auth.uid()) and status in ('draft','changes_requested')) with check(user_id=(select auth.uid()) and status in ('draft','changes_requested'));
create policy intermediary_staff_read on public.intermediary_profiles for select to authenticated using((select public.tra_is_curator_or_admin()));
create policy representation_party_read on public.artist_representations for select to authenticated using(public.tra_owns_intermediary(intermediary_id) or public.tra_owns_artist(artist_id) or (select public.tra_is_curator_or_admin()));
create policy phase1_curator_artist_read on public.artist_profiles for select to authenticated using((select public.tra_is_curator_or_admin()));
create policy phase1_curator_artwork_read on public.artworks for select to authenticated using((select public.tra_is_curator_or_admin()));
create policy phase1_curator_enquiry_read on public.buyer_enquiries for select to authenticated using((select public.tra_is_curator_or_admin()));

revoke all on public.intermediary_profiles,public.artist_representations from anon,authenticated;
grant select on public.intermediary_profiles,public.artist_representations to authenticated;
grant update(display_name,organisation_name,biography,email,phone,city,state,country,website) on public.intermediary_profiles to authenticated;

create trigger tra_intermediary_profiles_updated_at before update on public.intermediary_profiles for each row execute function public.tra_set_updated_at();
create trigger tra_artist_representations_updated_at before update on public.artist_representations for each row execute function public.tra_set_updated_at();

create function public.register_current_user_as_intermediary(p_display_name text,p_organisation text default null) returns uuid
language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare u uuid:=auth.uid();confirmed timestamptz;profile_id uuid;
begin
 if u is null then raise exception 'AUTHENTICATION_REQUIRED';end if;
 select email_confirmed_at into confirmed from auth.users where id=u;if confirmed is null then raise exception 'VERIFIED_EMAIL_REQUIRED';end if;
 if nullif(btrim(p_display_name),'') is null or char_length(btrim(p_display_name)) not between 2 and 120 then raise exception 'VALID_DISPLAY_NAME_REQUIRED';end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,0));
 insert into public.user_roles(user_id,role) values(u,'intermediary') on conflict do nothing;
 insert into public.intermediary_profiles(user_id,display_name,organisation_name) values(u,btrim(p_display_name),nullif(btrim(p_organisation),''))
 on conflict(user_id) do update set display_name=public.intermediary_profiles.display_name returning id into profile_id;
 return profile_id;
end$$;

create function public.save_intermediary_profile(p_data jsonb) returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare u uuid:=auth.uid();profile_id uuid;unknown text;
begin
 if u is null then raise exception 'AUTHENTICATION_REQUIRED';end if;
 if not exists(select 1 from public.user_roles where user_id=u and role::text='intermediary') then raise exception 'INTERMEDIARY_ROLE_REQUIRED';end if;
 select key into unknown from jsonb_object_keys(coalesce(p_data,'{}')) key where key not in ('display_name','organisation_name','biography','email','phone','city','state','country','website') limit 1;
 if unknown is not null then raise exception 'UNKNOWN_PROFILE_FIELD';end if;
 update public.intermediary_profiles set display_name=coalesce(nullif(btrim(p_data->>'display_name'),''),display_name),organisation_name=coalesce(p_data->>'organisation_name',organisation_name),biography=coalesce(p_data->>'biography',biography),email=coalesce(p_data->>'email',email),phone=coalesce(p_data->>'phone',phone),city=coalesce(p_data->>'city',city),state=coalesce(p_data->>'state',state),country=coalesce(nullif(p_data->>'country',''),country),website=coalesce(p_data->>'website',website) where user_id=u and status in ('draft','changes_requested') returning id into profile_id;
 if profile_id is null then raise exception 'INTERMEDIARY_PROFILE_NOT_EDITABLE';end if;return profile_id;
end$$;

create function public.submit_intermediary_profile() returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare profile_id uuid;
begin
 update public.intermediary_profiles set status='submitted',submitted_at=clock_timestamp() where user_id=auth.uid() and status in ('draft','changes_requested') and nullif(btrim(display_name),'') is not null and nullif(btrim(email),'') is not null returning id into profile_id;
 if profile_id is null then raise exception 'INTERMEDIARY_PROFILE_INCOMPLETE';end if;
 insert into public.audit_events(actor_id,action,entity_type,entity_id) values(auth.uid(),'intermediary.submitted','intermediary_profile',profile_id);
 return profile_id;
end$$;

create function public.request_artist_representation(p_artist uuid,p_scopes jsonb,p_note text default null) returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare intermediary_id uuid;representation_id uuid;
begin
 select id into intermediary_id from public.intermediary_profiles where user_id=auth.uid() and status='approved';
 if intermediary_id is null then raise exception 'APPROVED_INTERMEDIARY_REQUIRED';end if;
 if not exists(select 1 from public.artist_profiles where id=p_artist and status='approved') then raise exception 'APPROVED_ARTIST_REQUIRED';end if;
 insert into public.artist_representations(artist_id,intermediary_id,can_submit_artwork,can_view_fulfilment,can_manage_profile,request_note)
 values(p_artist,intermediary_id,coalesce((p_scopes->>'can_submit_artwork')::boolean,false),coalesce((p_scopes->>'can_view_fulfilment')::boolean,false),coalesce((p_scopes->>'can_manage_profile')::boolean,false),left(p_note,2000)) returning id into representation_id;
 insert into public.audit_events(actor_id,action,entity_type,entity_id) values(auth.uid(),'representation.requested','artist_representation',representation_id);return representation_id;
end$$;

create function public.respond_to_representation(p_representation uuid,p_accept boolean) returns text language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare next_status public.representation_status;
begin
 next_status:=case when p_accept then 'pending_admin' else 'rejected' end;
 update public.artist_representations r set status=next_status,artist_responded_at=clock_timestamp() where r.id=p_representation and r.status='pending_artist' and public.tra_owns_artist(r.artist_id);
 if not found then raise exception 'REPRESENTATION_NOT_ACTIONABLE';end if;
 insert into public.audit_events(actor_id,action,entity_type,entity_id,new_data) values(auth.uid(),'representation.artist_response','artist_representation',p_representation,jsonb_build_object('accepted',p_accept));return next_status::text;
end$$;

create function public.submit_artist_artwork(p_data jsonb) returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare artist_id uuid;artwork_id uuid;title text;declaration text;expected bigint;
begin
 select id into artist_id from public.artist_profiles where user_id=auth.uid() and status='approved';if artist_id is null then raise exception 'APPROVED_ARTIST_REQUIRED';end if;
 title:=nullif(btrim(p_data->>'title'),'');declaration:=nullif(btrim(p_data->>'declaration'),'');expected:=nullif(p_data->>'artist_expected_paise','')::bigint;
 if title is null or char_length(title)>200 or declaration is null or char_length(declaration)<20 then raise exception 'ARTWORK_SUBMISSION_INCOMPLETE';end if;
 if expected is not null and expected<0 then raise exception 'INVALID_EXPECTED_PRICE';end if;
 insert into public.artworks(artist_id,title,description,inspiration,year_created,width_cm,height_cm,framed,artist_expected_paise,status,artist_remarks,declaration_accepted_at,submitted_at)
 values(artist_id,title,nullif(p_data->>'description',''),nullif(p_data->>'inspiration',''),nullif(p_data->>'year_created','')::integer,nullif(p_data->>'width_cm','')::numeric,nullif(p_data->>'height_cm','')::numeric,nullif(p_data->>'framed','')::boolean,expected,'submitted',nullif(p_data->>'artist_remarks',''),clock_timestamp(),clock_timestamp()) returning id into artwork_id;
 insert into public.artwork_declarations(artwork_id,artist_user_id,declaration_snapshot) values(artwork_id,auth.uid(),declaration);
 insert into public.audit_events(actor_id,action,entity_type,entity_id) values(auth.uid(),'artwork.submitted','artwork',artwork_id);return artwork_id;
end$$;

create function public.review_phase1_entity(p_entity_type text,p_entity uuid,p_decision text,p_remarks text default null,p_final_price_paise bigint default null) returns text
language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare is_admin boolean:=public.tra_is_admin();is_curator boolean:=public.tra_is_curator_or_admin();old_status text;decision text:=lower(p_decision);
begin
 if not is_curator then raise exception 'FORBIDDEN';end if;
 if p_entity_type='artist' then
  if decision not in ('under_review','changes_requested','approved','rejected','suspended') or (not is_admin and decision in ('approved','rejected','suspended')) then raise exception 'DECISION_NOT_ALLOWED';end if;
  select status::text into old_status from public.artist_profiles where id=p_entity for update;if old_status is null then raise exception 'NOT_FOUND';end if;
  update public.artist_profiles set status=decision::public.artist_status,admin_remarks=left(p_remarks,5000),reviewed_by=auth.uid(),reviewed_at=clock_timestamp(),public_visible=case when decision='approved' then public_visible else false end where id=p_entity;
 elsif p_entity_type='intermediary' then
  if decision not in ('under_review','changes_requested','approved','rejected','suspended') or (not is_admin and decision in ('approved','rejected','suspended')) then raise exception 'DECISION_NOT_ALLOWED';end if;
  select status::text into old_status from public.intermediary_profiles where id=p_entity for update;if old_status is null then raise exception 'NOT_FOUND';end if;
  update public.intermediary_profiles set status=decision::public.intermediary_status,admin_remarks=left(p_remarks,5000),reviewed_by=auth.uid(),reviewed_at=clock_timestamp() where id=p_entity;
 elsif p_entity_type='artwork' then
  if decision not in ('under_review','changes_requested','approved','rejected','published','unpublished') or (not is_admin and decision in ('approved','rejected','published','unpublished')) then raise exception 'DECISION_NOT_ALLOWED';end if;
  select status::text into old_status from public.artworks where id=p_entity for update;if old_status is null then raise exception 'NOT_FOUND';end if;
  if decision='published' and (p_final_price_paise is null or p_final_price_paise<=0 or not exists(select 1 from public.artwork_media where artwork_id=p_entity and is_approved)) then raise exception 'PUBLICATION_REQUIREMENTS_NOT_MET';end if;
  update public.artworks set status=decision::public.artwork_status,admin_remarks=left(p_remarks,5000),reviewed_by=auth.uid(),final_price_paise=coalesce(p_final_price_paise,final_price_paise),published_at=case when decision='published' then clock_timestamp() else published_at end where id=p_entity;
 else raise exception 'UNKNOWN_ENTITY_TYPE';end if;
 insert into public.status_history(entity_type,entity_id,from_status,to_status,actor_id,remarks) values(p_entity_type,p_entity,old_status,decision,auth.uid(),left(p_remarks,5000));
 insert into public.audit_events(actor_id,action,entity_type,entity_id,previous_data,new_data) values(auth.uid(),'review.decision',p_entity_type,p_entity,jsonb_build_object('status',old_status),jsonb_build_object('status',decision));return decision;
end$$;

create function public.review_artist_representation(p_representation uuid,p_approve boolean,p_remarks text default null) returns text language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare next_status public.representation_status:=case when p_approve then 'approved' else 'rejected' end;
begin
 if not public.tra_is_admin() then raise exception 'FORBIDDEN';end if;
 update public.artist_representations set status=next_status,admin_remarks=left(p_remarks,5000),reviewed_by=auth.uid(),reviewed_at=clock_timestamp(),starts_at=case when p_approve then clock_timestamp() else null end where id=p_representation and status='pending_admin';if not found then raise exception 'REPRESENTATION_NOT_ACTIONABLE';end if;
 insert into public.audit_events(actor_id,action,entity_type,entity_id,new_data) values(auth.uid(),'representation.reviewed','artist_representation',p_representation,jsonb_build_object('status',next_status));return next_status::text;
end$$;

create function public.set_artwork_availability(p_artwork uuid,p_status text,p_remarks text default null) returns text language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare old_status text;
begin
 if not public.tra_is_admin() then raise exception 'FORBIDDEN';end if;if p_status not in ('published','unpublished','reserved','sold') then raise exception 'INVALID_AVAILABILITY';end if;
 select status::text into old_status from public.artworks where id=p_artwork for update;if old_status is null then raise exception 'NOT_FOUND';end if;
 if p_status='published' and (not exists(select 1 from public.artwork_media where artwork_id=p_artwork and is_approved) or coalesce((select final_price_paise from public.artworks where id=p_artwork),0)<=0) then raise exception 'PUBLICATION_REQUIREMENTS_NOT_MET';end if;
 if p_status in ('published','unpublished') and (exists(select 1 from public.sales where artwork_id=p_artwork and status in ('reserved','awaiting_payment','paid','fulfilment','completed')) or exists(select 1 from public.auction_lots where artwork_id=p_artwork and status in ('approved','scheduled','live','sold'))) then raise exception 'ARTWORK_COMMERCIALLY_LOCKED';end if;
 update public.artworks set status=p_status::public.artwork_status,admin_remarks=coalesce(left(p_remarks,5000),admin_remarks) where id=p_artwork;
 insert into public.status_history(entity_type,entity_id,from_status,to_status,actor_id,remarks) values('artwork',p_artwork,old_status,p_status,auth.uid(),left(p_remarks,5000));return p_status;
end$$;

do $$declare f regprocedure;begin
 foreach f in array array['public.register_current_user_as_intermediary(text,text)'::regprocedure,'public.save_intermediary_profile(jsonb)'::regprocedure,'public.submit_intermediary_profile()'::regprocedure,'public.request_artist_representation(uuid,jsonb,text)'::regprocedure,'public.respond_to_representation(uuid,boolean)'::regprocedure,'public.submit_artist_artwork(jsonb)'::regprocedure,'public.review_phase1_entity(text,uuid,text,text,bigint)'::regprocedure,'public.review_artist_representation(uuid,boolean,text)'::regprocedure,'public.set_artwork_availability(uuid,text,text)'::regprocedure] loop execute format('revoke all on function %s from public,anon',f);end loop;end$$;
grant execute on function public.register_current_user_as_intermediary(text,text),public.save_intermediary_profile(jsonb),public.submit_intermediary_profile(),public.request_artist_representation(uuid,jsonb,text),public.respond_to_representation(uuid,boolean),public.submit_artist_artwork(jsonb) to authenticated;
grant execute on function public.review_phase1_entity(text,uuid,text,text,bigint),public.review_artist_representation(uuid,boolean,text),public.set_artwork_availability(uuid,text,text) to authenticated;
commit;
