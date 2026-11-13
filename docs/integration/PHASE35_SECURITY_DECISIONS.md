# Phase 3.5 security decision recommendations

These recommendations require approval; none is implemented by this phase.

## 1. Clerk-to-Supabase identity linking

Recommendation: do not perform automatic linking. Keep Supabase as the canonical identity and require a dual challenge proving control of the current Supabase account and legacy Clerk account. Ambiguous matches, changed emails and privileged accounts require two-person manual review. Preserve the Supabase UUID; store only a one-way legacy identifier and audited evidence category. Never migrate passwords, sessions or administrative roles.

## 2. Initial Super Admin

Recommendation: approve the Phase 3 UUID-specific, two-person bootstrap runbook for development only. Require a verified email and MFA, create two independent Super Admin accounts before operational use, verify the audit event, and prohibit email-based bootstrap logic. All later changes use the audited RPC. Production needs a separate change approval.

## 3. Finance participation in auctions

Recommendation: retain the strict prohibition whenever an identity has the Finance / Operations role, including multi-role identities. A staff member wishing to collect art should use a separate, independently verified collector identity with conflict disclosure. This avoids access to payment/settlement information influencing bids.

## 4. Invitation delivery

Recommendation: use a server-only outbox worker with an approved transactional email provider. Deliver the single-use token only to the normalized invited address; never log or persist plaintext tokens. Default expiry should be 24 hours, with rate limits, revocation, resend-as-new-token, delivery audit metadata and generic public errors. Super Admin must remain non-invitational.

## 5. Artist–intermediary representation

Recommendation: require intermediary request, explicit artist consent and administrative approval. Every relationship must declare individual scopes and start/expiry dates. Settlement access is off by default and needs a separate scope/approval. Either party may revoke immediately; revocation must invalidate active access without waiting for token refresh and retain immutable audit history.

## 6. Suspension and reactivation

Recommendation: Super Admin only for privileged, Finance and Admin accounts; ordinary-user suspension may later be delegated under a separate permission. The database status change and Supabase Auth session revocation must form one operational workflow. Reactivation requires a reason and reviewer, does not restore separately revoked roles/representations, and requires fresh authentication. High-risk reactivation should require two-person approval.

