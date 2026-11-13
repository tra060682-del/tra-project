# Phase 3.5 RLS and transactional security results

Database-level result: PASS against the disposable development schema clone.

## Role and isolation matrix

| Scenario | Expected | Result |
|---|---:|---:|
| Anonymous access to permission overrides/invitations | Denied | PASS |
| Super Admin named permissions | Allowed | PASS |
| Super Admin self-role change | Denied | PASS |
| Admin auction operations | Allowed | PASS |
| Admin role/Super Admin escalation | Denied | PASS |
| Protected-permission override granted to Admin | Ignored | PASS |
| Curator artwork review | Allowed | PASS |
| Curator direct Admin-role insert | Denied | PASS |
| Artist reads own draft artwork | Allowed | PASS |
| Artist reads another artist’s private draft | Denied | PASS |
| Artist self-offer | Denied | PASS |
| Approved intermediary scope | Allowed | PASS |
| Unapproved intermediary scope | Denied | PASS |
| Artist revokes representation | Immediate denial | PASS |
| Collector reads own offer | Allowed | PASS |
| Collector reads another collector’s offer | Denied | PASS |
| Advisor reads enquiries | Allowed | PASS |
| Finance reads payment/audit records | Allowed | PASS |
| Finance modifies audit record | Denied | PASS |
| Finance participates in auction | Denied | PASS |
| Role revocation | Immediate permission loss | PASS |
| Suspended user private read | Denied | PASS |
| Suspended user protected write/RPC | Denied | PASS |
| Reactivated user active status | Restored | PASS |
| Email-bound invitation acceptance | Allowed once | PASS |
| Invitation replay | Denied | PASS |

## Transactional controls

| Control | Result |
|---|---|
| Concurrent proxy bids serialize correctly | PASS |
| Bid request replay is idempotent | PASS |
| Bid maximum remains private | PASS |
| Auction kill switch | PASS |
| Artist/admin conflict-of-interest checks | PASS |
| Finance bidding conflict | PASS |
| Terminal lot immutability | PASS |
| Auction close and audit events | PASS |
| Offer authentication, availability and self-dealing checks | PASS |
| Payment-event RLS | PASS |
| Ledger update/delete immutability | PASS |
| Audit-log write protection | PASS |

All auction and payment data was synthetic and local. No provider calls, real payment operations, live auctions, or remote records were used.

## Residual limitations

- The rehearsal validates PostgreSQL behavior, not session revocation at the Supabase Auth gateway. Suspension still requires an operational Admin API session-revocation step.
- The main migration is intentionally one-shot. Only enum additions are idempotently rerunnable.
- Rollback retains enum labels.
- The invitation RPC creates/accepts secure tokens, but an approved delivery worker and message provider are not implemented.
- Identity linking was not executed.

