# Phase 3 identity linking plan

Identity linking remains approval-gated and is not implemented in Phase 3.

## Preconditions

1. Define the authoritative legacy source and obtain a verified export containing immutable legacy ID, normalized email, verification state and source timestamp.
2. Match only to a single existing Supabase identity. Email equality alone is insufficient for privileged or financially active accounts.
3. Require fresh control of both identities, or a manual review using documented evidence. Privileged accounts require two-person approval.
4. Reject ambiguous, duplicate, recycled-domain and conflicting-email matches. Never create a second Supabase user to resolve a conflict.
5. Preserve the existing Supabase UUID. Store a one-way link record and source metadata, not legacy passwords or tokens.

## Proposed workflow

Create a pending link request with a random, hashed, short-lived challenge. Verify the current Supabase session, current email challenge, and legacy-account challenge. A reviewer confirms the match; a transactional RPC locks both identities, checks no prior link, records the link and audit event, then consumes the challenge. Roles are reviewed separately and are never copied automatically.

Revocation disables the link metadata only; it does not delete either identity or silently change roles. All decisions must record actor, reason, evidence category and timestamp. Rate limiting, replay prevention and notification to both addresses are required.

## Decisions still required

- Accepted legacy evidence and reviewer group.
- Treatment of users without access to the legacy email.
- Retention period and privacy basis for match evidence.
- Whether links are reversible and the dispute process.
- Role reconciliation rules for legacy administrators and intermediaries.

