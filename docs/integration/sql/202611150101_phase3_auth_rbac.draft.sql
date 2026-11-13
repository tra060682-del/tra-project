-- PROPOSAL ONLY. Additive Phase 3 RBAC for development project ocstvctvmychromkcurw.
-- Depends on 202611150100 being committed separately. Never run against production.
begin;
do $$begin
 if current_setting('app.tra_phase3_target',true) is distinct from 'ocstvctvmychromkcurw:approved-development-only' then raise exception 'TRA_PHASE3_TARGET_NOT_APPROVED'; end if;
 if to_regclass('public.profiles') is null or to_regclass('public.user_roles') is null or to_regclass('public.audit_events') is null then raise exception 'TRA_PHASE3_PREFLIGHT_FAILED'; end if;
end$$;

do $$begin create type public.account_status as enum ('active','suspended','deactivated','archived'); exception when duplicate_object then null; end$$;
alter table public.profiles add column if not exists account_status public.account_status not null default 'active';
alter table public.profiles add column if not exists status_changed_at timestamptz;
alter table public.profiles add column if not exists status_changed_by uuid references auth.users(id) on delete restrict;
create index if not exists profiles_account_status_idx on public.profiles(account_status,id);

create table if not exists public.role_permissions(
 role public.tra_role not null, permission text not null,
 created_at timestamptz not null default now(), primary key(role,permission),
 constraint role_permission_name_check check(permission ~ '^[a-z]+(\.[a-z]+)+$')
);
create table if not exists public.user_permission_overrides(
 user_id uuid not null references auth.users(id) on delete cascade, permission text not null,
 effect text not null check(effect in ('grant','revoke')),expires_at timestamptz,
 reason text not null check(char_length(btrim(reason)) between 10 and 1000),
 created_by uuid not null references auth.users(id) on delete restrict,created_at timestamptz not null default now(),
 primary key(user_id,permission),constraint permission_override_name_check check(permission ~ '^[a-z]+(\.[a-z]+)+$')
);
create table if not exists public.account_invitations(
 id uuid primary key default gen_random_uuid(),email text not null,role public.tra_role not null,
 token_hash text not null unique,status text not null default 'pending' check(status in ('pending','accepted','revoked','expired')),
 expires_at timestamptz not null,created_by uuid not null references auth.users(id) on delete restrict,
 accepted_by uuid references auth.users(id) on delete restrict,accepted_at timestamptz,revoked_at timestamptz,
 created_at timestamptz not null default now(),constraint invitation_email_check check(email=lower(email) and position('@' in email)>1)
);
create unique index if not exists account_invitation_pending_uq on public.account_invitations(email,role) where status='pending';
alter table public.artist_representations add column if not exists revoked_at timestamptz;
alter table public.artist_representations add column if not exists revoked_by uuid references auth.users(id) on delete restrict;
alter table public.artist_representations add column if not exists revocation_reason text;

insert into public.role_permissions(role,permission) values
 ('admin','users.view'),('admin','artists.review'),('admin','artworks.review'),('admin','intermediaries.review'),('admin','enquiries.manage'),('admin','offers.manage'),('admin','auctions.manage'),('admin','bidders.manage'),('admin','orders.manage'),('admin','requests.manage'),('admin','certificates.manage'),('admin','content.manage'),('admin','legal.draft'),('admin','reports.view'),('admin','audit.view'),
 ('curator','artists.review'),('curator','artworks.review'),('curator','offers.manage'),('curator','certificates.manage'),('curator','content.manage'),('curator','legal.draft'),
 ('advisor','enquiries.manage'),('advisor','requests.manage'),
 ('finance','orders.manage'),('finance','payments.manage'),('finance','settlements.manage'),('finance','reports.view'),('finance','audit.view')
on conflict do nothing;

create or replace function public.tra_account_is_active(p_user uuid default auth.uid()) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.profiles where id=p_user and account_status='active')$$;
create or replace function public.tra_has_permission(p_permission text,p_user uuid default auth.uid()) returns boolean language sql stable security definer set search_path='' as $$
 select public.tra_account_is_active(p_user) and
 not exists(select 1 from public.user_permission_overrides where user_id=p_user and permission=p_permission and effect='revoke' and (expires_at is null or expires_at>clock_timestamp())) and
 (p_permission not in ('roles.manage','settings.manage','integrations.manage') or exists(select 1 from public.user_roles where user_id=p_user and role='super_admin')) and
 (exists(select 1 from public.user_roles where user_id=p_user and role='super_admin') or
  exists(select 1 from public.user_permission_overrides where user_id=p_user and permission=p_permission and effect='grant' and (expires_at is null or expires_at>clock_timestamp())) or
  exists(select 1 from public.user_roles ur join public.role_permissions rp using(role) where ur.user_id=p_user and rp.permission=p_permission))
$$;
create or replace function public.tra_representation_allows(p_representation uuid,p_scope text,p_user uuid default auth.uid()) returns boolean language sql stable security definer set search_path='' as $$
 select public.tra_account_is_active(p_user) and exists(
  select 1 from public.artist_representations r join public.intermediary_profiles i on i.id=r.intermediary_id
  where r.id=p_representation and i.user_id=p_user and i.status='approved' and r.status='approved' and r.revoked_at is null
  and coalesce(r.starts_at,'-infinity'::timestamptz)<=clock_timestamp() and coalesce(r.ends_at,'infinity'::timestamptz)>clock_timestamp()
  and case p_scope when 'submit_artwork' then r.can_submit_artwork when 'view_fulfilment' then r.can_view_fulfilment when 'manage_profile' then r.can_manage_profile else false end)
$$;

revoke all on function public.tra_account_is_active(uuid),public.tra_has_permission(text,uuid),public.tra_representation_allows(uuid,text,uuid) from public;
grant execute on function public.tra_account_is_active(uuid),public.tra_has_permission(text,uuid),public.tra_representation_allows(uuid,text,uuid) to authenticated,service_role;

-- Restrictive policies compose with every legacy permissive policy so an inactive
-- authenticated account cannot read or mutate private records. Anonymous public
-- catalogue policies are unaffected because this gate applies to authenticated only.
do $$declare t text;begin foreach t in array array['user_roles','profiles','artist_profiles','intermediary_profiles','artist_representations','artworks','auction_submissions','auction_watchlists','bidder_eligibility','auction_proxy_bids','auction_bid_requests','sales','buyer_enquiries','audit_events'] loop if to_regclass('public.'||t) is not null then execute format('drop policy if exists phase3_active_account_gate on public.%I',t);execute format('create policy phase3_active_account_gate on public.%I as restrictive for all to authenticated using (public.tra_account_is_active()) with check (public.tra_account_is_active())',t);end if;end loop;end$$;

create or replace function public.tra_require_active_actor() returns trigger language plpgsql security definer set search_path='' as $$begin if auth.uid() is not null and not public.tra_account_is_active(auth.uid()) then raise exception 'ACCOUNT_INACTIVE'; end if;if tg_table_name in ('auction_proxy_bids','auction_bid_requests') and exists(select 1 from public.user_roles where user_id=auth.uid() and role='finance') then raise exception 'OPERATIONAL_ROLE_CANNOT_BID';end if;if tg_op='DELETE' then return old;end if;return new;end$$;
do $$declare t text;begin foreach t in array array['user_roles','artist_profiles','intermediary_profiles','artist_representations','artworks','auction_submissions','auction_watchlists','bidder_eligibility','auction_proxy_bids','auction_bid_requests','sales'] loop if to_regclass('public.'||t) is not null then execute format('drop trigger if exists tra_active_actor_guard on public.%I',t);execute format('create trigger tra_active_actor_guard before insert or update or delete on public.%I for each row execute function public.tra_require_active_actor()',t);end if;end loop;end$$;

create or replace function public.tra_manage_user_role(p_user_id uuid,p_role public.tra_role,p_operation text,p_reason text) returns void language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare actor uuid:=auth.uid();begin
 if not public.tra_has_permission('roles.manage',actor) then raise exception 'PERMISSION_DENIED'; end if;
 if p_operation not in ('grant','revoke') or char_length(btrim(p_reason)) not between 10 and 1000 then raise exception 'INVALID_REQUEST'; end if;
 if actor=p_user_id and p_role='super_admin' then raise exception 'SELF_SUPER_ADMIN_CHANGE_FORBIDDEN'; end if;
 perform pg_advisory_xact_lock(hashtextextended('tra-role:'||p_user_id::text,0));
 if p_operation='grant' then insert into public.user_roles(user_id,role) values(p_user_id,p_role) on conflict do nothing;
 else
  if p_role='super_admin' and (select count(*) from public.user_roles where role='super_admin')<=1 then raise exception 'LAST_SUPER_ADMIN_REQUIRED'; end if;
  delete from public.user_roles where user_id=p_user_id and role=p_role;
 end if;
 insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata) values(actor,'access.role_'||p_operation,'user',p_user_id,jsonb_build_object('role',p_role,'reason',btrim(p_reason)));
end$$;
create or replace function public.tra_set_account_status(p_user_id uuid,p_status public.account_status,p_reason text) returns void language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare actor uuid:=auth.uid();begin
 if not public.tra_has_permission('users.manage',actor) then raise exception 'PERMISSION_DENIED'; end if;
 if actor=p_user_id then raise exception 'SELF_STATUS_CHANGE_FORBIDDEN'; end if;
 if char_length(btrim(p_reason)) not between 10 and 1000 then raise exception 'REASON_REQUIRED'; end if;
 update public.profiles set account_status=p_status,status_changed_at=clock_timestamp(),status_changed_by=actor where id=p_user_id;
 if not found then raise exception 'USER_NOT_FOUND'; end if;
 insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata) values(actor,'access.status_changed','user',p_user_id,jsonb_build_object('status',p_status,'reason',btrim(p_reason)));
end$$;
create or replace function public.tra_revoke_representation(p_representation_id uuid,p_reason text) returns void language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare actor uuid:=auth.uid();r public.artist_representations%rowtype;begin
 if not public.tra_account_is_active(actor) or char_length(btrim(p_reason)) not between 10 and 1000 then raise exception 'REQUEST_DENIED'; end if;
 select * into r from public.artist_representations where id=p_representation_id for update;
 if not found or r.status<>'approved' then raise exception 'REPRESENTATION_NOT_ACTIVE'; end if;
 if not (public.tra_owns_artist(r.artist_id) or public.tra_owns_intermediary(r.intermediary_id) or public.tra_has_permission('intermediaries.review',actor)) then raise exception 'PERMISSION_DENIED'; end if;
 update public.artist_representations set status='ended',ends_at=least(coalesce(ends_at,clock_timestamp()),clock_timestamp()),revoked_at=clock_timestamp(),revoked_by=actor,revocation_reason=btrim(p_reason) where id=p_representation_id;
 insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata) values(actor,'representation.revoked','artist_representation',p_representation_id,jsonb_build_object('reason',btrim(p_reason)));
end$$;
create or replace function public.tra_create_invitation(p_email text,p_role public.tra_role,p_expires_in_hours integer) returns text language plpgsql security definer set search_path=public,auth,extensions,pg_temp as $$
declare actor uuid:=auth.uid();token text:=encode(gen_random_bytes(32),'hex');invitation uuid;begin
 if not public.tra_has_permission('roles.manage',actor) then raise exception 'PERMISSION_DENIED'; end if;
 if p_role='super_admin' then raise exception 'SUPER_ADMIN_INVITATION_FORBIDDEN'; end if;
 if p_expires_in_hours not between 1 and 168 then raise exception 'INVALID_EXPIRY'; end if;
 insert into public.account_invitations(email,role,token_hash,expires_at,created_by) values(lower(btrim(p_email)),p_role,crypt(token,gen_salt('bf')),clock_timestamp()+make_interval(hours=>p_expires_in_hours),actor) returning id into invitation;
 insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata) values(actor,'invitation.created','account_invitation',invitation,jsonb_build_object('role',p_role));return token;
end$$;
create or replace function public.tra_revoke_invitation(p_invitation_id uuid,p_reason text) returns void language plpgsql security definer set search_path=public,auth,pg_temp as $$declare actor uuid:=auth.uid();begin if not public.tra_has_permission('roles.manage',actor) or char_length(btrim(p_reason)) not between 10 and 1000 then raise exception 'PERMISSION_DENIED';end if;update public.account_invitations set status='revoked',revoked_at=clock_timestamp() where id=p_invitation_id and status='pending';if not found then raise exception 'INVITATION_NOT_PENDING';end if;insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata) values(actor,'invitation.revoked','account_invitation',p_invitation_id,jsonb_build_object('reason',btrim(p_reason)));end$$;
create or replace function public.tra_accept_invitation(p_token text) returns public.tra_role language plpgsql security definer set search_path=public,auth,extensions,pg_temp as $$declare actor uuid:=auth.uid();inv public.account_invitations%rowtype;actor_email text;begin if not public.tra_account_is_active(actor) then raise exception 'ACCOUNT_INACTIVE';end if;select lower(email) into actor_email from auth.users where id=actor and email_confirmed_at is not null;select * into inv from public.account_invitations where status='pending' and expires_at>clock_timestamp() and token_hash=crypt(p_token,token_hash) for update;if not found or actor_email is distinct from inv.email then raise exception 'INVITATION_INVALID';end if;if inv.role='super_admin' then raise exception 'SUPER_ADMIN_INVITATION_FORBIDDEN';end if;insert into public.user_roles(user_id,role) values(actor,inv.role) on conflict do nothing;update public.account_invitations set status='accepted',accepted_by=actor,accepted_at=clock_timestamp() where id=inv.id;insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata) values(actor,'invitation.accepted','account_invitation',inv.id,jsonb_build_object('role',inv.role));return inv.role;end$$;
revoke all on function public.tra_manage_user_role(uuid,public.tra_role,text,text),public.tra_set_account_status(uuid,public.account_status,text),public.tra_revoke_representation(uuid,text),public.tra_create_invitation(text,public.tra_role,integer),public.tra_revoke_invitation(uuid,text),public.tra_accept_invitation(text) from public;
grant execute on function public.tra_manage_user_role(uuid,public.tra_role,text,text),public.tra_set_account_status(uuid,public.account_status,text),public.tra_revoke_representation(uuid,text),public.tra_create_invitation(text,public.tra_role,integer),public.tra_revoke_invitation(uuid,text),public.tra_accept_invitation(text) to authenticated;

alter table public.role_permissions enable row level security;alter table public.user_permission_overrides enable row level security;alter table public.account_invitations enable row level security;
create policy role_permissions_inspect on public.role_permissions for select to authenticated using(public.tra_has_permission('roles.manage') or exists(select 1 from public.user_roles where user_id=auth.uid() and role=role_permissions.role));
create policy overrides_inspect on public.user_permission_overrides for select to authenticated using(user_id=auth.uid() or public.tra_has_permission('roles.manage'));
create policy invitations_manage_read on public.account_invitations for select to authenticated using(public.tra_has_permission('roles.manage'));
create policy phase3_enquiries_permission_read on public.buyer_enquiries for select to authenticated using(public.tra_has_permission('enquiries.manage'));
create policy phase3_audit_permission_read on public.audit_events for select to authenticated using(public.tra_has_permission('audit.view'));
create policy phase3_sales_permission_read on public.sales for select to authenticated using(public.tra_has_permission('orders.manage'));
revoke all on public.role_permissions,public.user_permission_overrides,public.account_invitations from anon,authenticated;
grant select on public.role_permissions,public.user_permission_overrides,public.account_invitations to authenticated;
commit;

