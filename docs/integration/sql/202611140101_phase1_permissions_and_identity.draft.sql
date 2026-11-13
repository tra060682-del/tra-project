-- SUPERSEDED DESIGN DRAFT. DO NOT APPLY. Phase 3 migration 202611150101 owns
-- account status, role permissions, permission overrides and authorization helpers.
-- Retained only as an historical Phase 1 contract.
-- Target: development project ocstvctvmychromkcurw only.
-- Structural intent: additive roles/permissions and account-state enforcement.

begin;

do $$
begin
  if current_setting('app.tra_phase1_target', true) is distinct from 'ocstvctvmychromkcurw:approved-development-only' then
    raise exception 'PHASE1_DRAFT_REFUSED';
  end if;
end $$;

alter table public.profiles add column if not exists account_status text not null default 'active';
alter table public.profiles add column if not exists last_seen_at timestamptz;
alter table public.profiles add column if not exists metadata jsonb not null default '{}'::jsonb;

do $$ begin
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_account_status_check') then
    alter table public.profiles add constraint profiles_account_status_check
      check (account_status in ('active','suspended','deactivated','archived')) not valid;
  end if;
end $$;
alter table public.profiles validate constraint profiles_account_status_check;

create table if not exists public.role_permissions (
  role public.tra_role not null,
  permission text not null,
  created_at timestamptz not null default now(),
  primary key (role, permission),
  constraint role_permissions_name_check check (permission ~ '^[a-z][a-z0-9_.]{2,80}$')
);

create table if not exists public.user_permission_overrides (
  user_id uuid not null references auth.users(id) on delete cascade,
  permission text not null,
  effect text not null,
  granted_by uuid not null references auth.users(id),
  reason text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (user_id, permission),
  constraint user_permission_effect_check check (effect in ('grant','revoke')),
  constraint user_permission_name_check check (permission ~ '^[a-z][a-z0-9_.]{2,80}$'),
  constraint user_permission_no_self_grant check (user_id <> granted_by or effect='revoke')
);

create index if not exists user_permission_overrides_active_idx
  on public.user_permission_overrides(user_id, permission)
  where expires_at is null;

alter table public.role_permissions enable row level security;
alter table public.user_permission_overrides enable row level security;

create or replace function public.tra_has_role(p_role public.tra_role)
returns boolean language sql stable security definer
set search_path=public,auth,pg_temp
as $$ select exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role=p_role) $$;

create or replace function public.tra_has_permission(p_permission text)
returns boolean language sql stable security definer
set search_path=public,auth,pg_temp
as $$
  select auth.uid() is not null
    and coalesce((select p.account_status='active' from public.profiles p where p.id=auth.uid()), false)
    and not exists (
      select 1 from public.user_permission_overrides o
      where o.user_id=auth.uid() and o.permission=p_permission and o.effect='revoke'
        and (o.expires_at is null or o.expires_at>now())
    )
    and (
      exists (
        select 1 from public.user_roles r
        join public.role_permissions rp on rp.role=r.role
        where r.user_id=auth.uid() and rp.permission=p_permission
      )
      or exists (
        select 1 from public.user_permission_overrides o
        where o.user_id=auth.uid() and o.permission=p_permission and o.effect='grant'
          and (o.expires_at is null or o.expires_at>now())
      )
    )
$$;

revoke all on function public.tra_has_role(public.tra_role) from public;
revoke all on function public.tra_has_permission(text) from public;
grant execute on function public.tra_has_role(public.tra_role) to authenticated;
grant execute on function public.tra_has_permission(text) to authenticated;

create or replace function public.tra_guard_protected_permission()
returns trigger language plpgsql security definer
set search_path=public,auth,pg_temp
as $$
begin
  if new.permission in ('roles.manage','settings.manage','integrations.manage')
     and not public.tra_has_role('super_admin'::public.tra_role) then
    raise exception 'SUPER_ADMIN_REQUIRED';
  end if;
  return new;
end $$;

drop trigger if exists tra_guard_protected_permission on public.user_permission_overrides;
create trigger tra_guard_protected_permission before insert or update
on public.user_permission_overrides for each row execute function public.tra_guard_protected_permission();

create policy role_permissions_read on public.role_permissions for select to authenticated
using (public.tra_has_permission('users.view'));
create policy role_permissions_manage on public.role_permissions for all to authenticated
using (public.tra_has_permission('roles.manage'))
with check (public.tra_has_permission('roles.manage'));
create policy permission_override_self_read on public.user_permission_overrides for select to authenticated
using (user_id=auth.uid() or public.tra_has_permission('users.manage'));
create policy permission_override_manage on public.user_permission_overrides for all to authenticated
using (public.tra_has_permission('roles.manage'))
with check (public.tra_has_permission('roles.manage'));

-- Default permissions. Protected permissions remain Super-Admin-only.
insert into public.role_permissions(role,permission) values
 ('super_admin','roles.manage'),('super_admin','users.view'),('super_admin','users.manage'),
 ('super_admin','artists.review'),('super_admin','artworks.review'),('super_admin','intermediaries.review'),
 ('super_admin','enquiries.manage'),('super_admin','offers.manage'),('super_admin','auctions.manage'),
 ('super_admin','bidders.manage'),('super_admin','orders.manage'),('super_admin','payments.manage'),
 ('super_admin','settlements.manage'),('super_admin','requests.manage'),('super_admin','certificates.manage'),
 ('super_admin','content.manage'),('super_admin','legal.draft'),('super_admin','legal.publish'),
 ('super_admin','reports.view'),('super_admin','audit.view'),('super_admin','settings.manage'),
 ('super_admin','integrations.manage'),
 ('admin','users.view'),('admin','artists.review'),('admin','artworks.review'),
 ('admin','intermediaries.review'),('admin','enquiries.manage'),('admin','offers.manage'),
 ('admin','auctions.manage'),('admin','bidders.manage'),('admin','orders.manage'),
 ('admin','requests.manage'),('admin','certificates.manage'),('admin','content.manage'),
 ('admin','legal.draft'),('admin','reports.view'),('admin','audit.view'),
 ('curator','artists.review'),('curator','artworks.review'),('curator','offers.manage'),
 ('curator','certificates.manage'),('curator','content.manage'),('curator','legal.draft'),
 ('finance','orders.manage'),('finance','payments.manage'),('finance','settlements.manage'),
 ('finance','reports.view'),('finance','audit.view'),
 ('advisor','enquiries.manage'),('advisor','requests.manage')
on conflict do nothing;

-- Direct role writes must be removed in the reviewed migration. Role changes go through a
-- locked RPC that prevents self-escalation and removal of the final Super Admin.

commit;
