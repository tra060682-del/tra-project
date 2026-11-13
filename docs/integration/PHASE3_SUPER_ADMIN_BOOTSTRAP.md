# Phase 3 Super Admin bootstrap

No migration, signup flow or email rule assigns the first Super Admin. Bootstrap requires explicit approval after the Phase 3 database proposal is applied to the development project.

## Required approvals

- Named approver and named operator must be different people.
- Confirm the exact Supabase project reference is `ocstvctvmychromkcurw`.
- Confirm the candidate UUID and verified email directly in Supabase Auth; do not select by email in the write statement.
- Confirm the candidate profile is active and has MFA according to the operational policy.
- Record the ticket/change reference and reason. Never paste access tokens into the ticket or repository.

## One-time development transaction

Replace the placeholders only in the approved database session. This is a runbook snippet, not a migration:

```sql
begin;
select set_config('app.tra_phase3_target','ocstvctvmychromkcurw:approved-development-only',true);
select id,email,email_confirmed_at from auth.users where id = '<approved-user-uuid>'::uuid for update;
-- Operator must verify exactly one expected row and a non-null email_confirmed_at before continuing.
insert into public.user_roles(user_id,role) values('<approved-user-uuid>'::uuid,'super_admin') on conflict do nothing;
insert into public.audit_events(actor_id,action,entity_type,entity_id,metadata)
values(null,'access.super_admin_bootstrapped','user','<approved-user-uuid>'::uuid,
       jsonb_build_object('change_reference','<approved-change-reference>','operator','<operator-identifier>'));
commit;
```

Immediately verify the role through a fresh login, verify `/admin/access`, inspect the audit row, and test a prohibited Admin escalation. If any check fails, revoke the new row in a separately approved transaction. Once one Super Admin exists, all later changes use `tra_manage_user_role`; the bootstrap procedure must not be repeated.

