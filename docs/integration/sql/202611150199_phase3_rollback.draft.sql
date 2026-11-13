-- Destructive rollback proposal. Back up and obtain separate approval before use.
begin;
drop function if exists public.tra_accept_invitation(text);
drop function if exists public.tra_revoke_invitation(uuid,text);
do $$declare t text;begin foreach t in array array['user_roles','artist_profiles','intermediary_profiles','artist_representations','artworks','auction_submissions','auction_watchlists','bidder_eligibility','proxy_bids','bid_requests','orders','payments'] loop if to_regclass('public.'||t) is not null then execute format('drop trigger if exists tra_active_actor_guard on public.%I',t);end if;end loop;end$$;
drop function if exists public.tra_require_active_actor();
drop function if exists public.tra_create_invitation(text,public.staff_role,integer);
drop function if exists public.tra_revoke_representation(uuid,text);
drop function if exists public.tra_set_account_status(uuid,public.account_status,text);
drop function if exists public.tra_manage_user_role(uuid,public.staff_role,text,text);
drop function if exists public.tra_representation_allows(uuid,text,uuid);
drop function if exists public.tra_has_permission(text,uuid);
drop function if exists public.tra_account_is_active(uuid);
drop table if exists public.account_invitations;
drop table if exists public.user_permission_overrides;
drop table if exists public.role_permissions;
alter table public.artist_representations drop column if exists revocation_reason,drop column if exists revoked_by,drop column if exists revoked_at;
alter table public.profiles drop column if exists status_changed_by,drop column if exists status_changed_at,drop column if exists account_status;
drop type if exists public.account_status;
commit;
-- PostgreSQL enum values are intentionally not removed; removing enum members requires a table/type rewrite.
