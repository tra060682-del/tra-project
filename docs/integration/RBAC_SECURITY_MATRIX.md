# RBAC and security matrix

Status: target authorization contract. UI navigation may mirror this matrix but never enforces it.

## Roles

| Role | Purpose | Default permissions | Prohibited boundaries |
|---|---|---|---|
| Super Admin | Owner-level governance | All named permissions; role/permission/configuration management | Cannot bypass immutable evidence, financial ledger, auction integrity or last-Super-Admin guard |
| Admin | Marketplace and operational administration | Artist/artwork/intermediary review, auctions, bidders, enquiries, offers, orders, requests, certificates, content draft/publish, reports/audit read, legal draft | No role escalation, secrets/integration configuration, or permission overrides by default |
| Curator | Curatorial review and content | Artist/artwork review recommendation, taxonomy/classification, content, offers, certificate review | No final privileged role changes, payment/settlement, platform settings or live-auction enablement |
| Artist | Owner workspace | Own profile, own artwork drafts/submission, own representation decisions, own sales/shipping/certificates/stories | No staff review fields, final price/publication, other artists, bidder administration or finance administration |
| Intermediary | Consent-scoped artist delegate | Own profile; represented artist actions explicitly granted and currently active | No action before artist consent/admin approval; no bank/identity/role changes; revocation takes effect immediately |
| Collector | Buyer/account workspace | Own wishlist, offers, bidder profile, bids, orders, payments, certificates, requests and preferences | No other collector data, proxy ceilings, staff modules or seller-only fields |
| Art Advisor | Enquiries and advisory service | Assigned enquiries and service requests; bounded customer/contact access | No artist publication, auction control, payments, role management or global settings |
| Finance / Operations | Payment, settlement and fulfilment | Orders/payment events/ledger/settlements/reconciliation/shipping; reports and audit read | No content publication, artist curation, role changes, bidder bidding, private identity documents unless explicitly required |

`super_admin`, `finance` and `advisor` are additive `tra_role` values. “Operations” is a Finance permission bundle, not a ninth role, until separation-of-duties review proves a separate role is necessary.

## Permission matrix

Legend: **M** manage/final decision, **R** read, **O** own records, **S** consent-scoped, **Rec** recommendation only, **—** denied.

| Capability | Super Admin | Admin | Curator | Artist | Intermediary | Collector | Art Advisor | Finance/Ops |
|---|---|---|---|---|---|---|---|---|
| Roles and permission overrides | M | — | — | — | — | — | — | — |
| Account suspension/recovery | M | M, except privileged peers | — | Own deactivation request | Own deactivation request | Own deactivation request | — | — |
| Platform settings | M | R selected | — | — | — | — | — | R operational only |
| Integration/secrets status | M | — | — | — | — | — | — | R status, never secret |
| Artist applications | M | M | Rec/R | O | S/R | — | — | — |
| Artwork draft/submission | M | M | Rec/R | O | S | — | — | — |
| Final price/publication | M | M | Rec | — | — | — | — | R |
| Taxonomy/classification | M | M | M/Rec | O suggestion | S suggestion | — | — | — |
| Artist–intermediary relationship | M | M final | R | O consent/revoke | O request/revoke | — | — | — |
| Enquiries | M | M | R | O artwork leads | S | O submitted | Assigned M | R where linked to order |
| Offers | M | M | R | O/respond | S/respond | O/create/respond | Assigned R | R |
| Auctions/lots | M | M | Rec/R | Own submissions/R | S submission | Public/R | — | R operational |
| Bidder eligibility | M | M | — | Own unrelated bidding | Own unrelated bidding | O | — | R risk-only |
| Bid placement/proxy maximum | Own unrelated lots only | Own unrelated lots only | Own unrelated lots only | Own unrelated lots only | Own unrelated lots only | O | Own unrelated lots only | Denied while acting operationally |
| Orders/sales | M | M | R | O seller view | S | O buyer view | Assigned R | M |
| Payments/refunds/ledger | M | R/M by explicit grant | — | O settlement summary | S summary | O payment status | — | M |
| Settlement | M | M by explicit grant | — | O | S entitlement | — | — | M |
| Shipping | M | M | — | O task | S task | O tracking | Assigned R | M |
| Certificates/private files | M | M | Review | O | S | O issued copy | — | R where order-linked |
| Legal draft/publish | M | Draft; publish by explicit grant | Draft/Rec | Accept | Accept | Accept | — | Accept operational terms |
| Journal/content | M | M | M | Own stories/quote approval | S stories | Bookmark | Rec | — |
| Notifications/preferences | M operational | R logs | Own | O | O | O | O | R delivery logs |
| Analytics/reports | M | R | Curatorial R | Own aggregate | Own aggregate | Own | Assigned aggregate | Financial R |
| Audit log | M | R | R relevant | Own evidence | Own evidence | Own evidence | Assigned evidence | R |

## Named permission defaults

| Permission | Default roles |
|---|---|
| `roles.manage` | Super Admin |
| `users.view` | Super Admin, Admin |
| `users.manage` | Super Admin; Admin only through constrained recovery/suspension RPCs |
| `artists.review` | Super Admin, Admin, Curator |
| `artworks.review` | Super Admin, Admin, Curator |
| `intermediaries.review` | Super Admin, Admin |
| `enquiries.manage` | Super Admin, Admin, Art Advisor |
| `offers.manage` | Super Admin, Admin, Curator |
| `auctions.manage` | Super Admin, Admin |
| `bidders.manage` | Super Admin, Admin |
| `orders.manage` | Super Admin, Admin, Finance/Ops |
| `payments.manage` | Super Admin, Finance/Ops |
| `settlements.manage` | Super Admin, Finance/Ops |
| `requests.manage` | Super Admin, Admin, Art Advisor |
| `certificates.manage` | Super Admin, Admin, Curator |
| `content.manage` | Super Admin, Admin, Curator |
| `legal.draft` | Super Admin, Admin, Curator |
| `legal.publish` | Super Admin or explicit Admin override |
| `reports.view` | Super Admin, Admin, Finance/Ops; scoped Curator/Advisor reports |
| `audit.view` | Super Admin, Admin, Finance/Ops; scoped Curator view |
| `settings.manage` | Super Admin |
| `integrations.manage` | Super Admin |

Overrides are explicit grant/revoke rows. A revoke wins over a grant. `roles.manage`, `settings.manage` and `integrations.manage` cannot be granted below Super Admin by ordinary application RPCs.

## Enforcement layers

1. Supabase verifies the session and supplies `auth.uid()`.
2. Route Handler/Server Action validates the request with Zod and checks the named permission for early failure.
3. RLS limits visible/mutable rows using stable `SECURITY DEFINER` helper functions with fixed `search_path`.
4. Transactional RPC checks ownership, scopes, state and money again under row/advisory locks.
5. Audit event records the actor, action, entity and before/after metadata.
6. Browser UI displays only allowed navigation but is never trusted.

## Mandatory security tests

| Test area | Required cases |
|---|---|
| Unauthenticated | Anonymous cannot read private profiles, roles, offers, orders, payment events, proxy ceilings, notifications, certificates/files, staging or audit; public catalogue/legal/certificate projections expose allow-listed fields only |
| Cross-user | Collector A cannot read/mutate Collector B data; Artist A cannot read Artist B private data; intermediaries cannot discover unrepresented artist operations |
| Artist ownership | Artist can edit only draft/changes-requested own records; cannot set final price, reviewed-by, published state, approved media or role |
| Intermediary consent | Request alone grants nothing; artist consent plus admin approval plus active date plus scope is required; each scope is tested independently |
| Permission revocation | Revoke wins immediately for API and direct database access; cached navigation cannot preserve authority; representation revoke blocks the next statement |
| Admin escalation | Admin cannot add `super_admin`, grant protected permissions, alter own role, recover/suspend a Super Admin, or remove the last Super Admin |
| Auction integrity | Anonymous/ineligible/unaccepted/related-party bid rejection; idempotent request replay; concurrent maxima; equal-max priority; reserve privacy; anti-sniping; close once; proxy ceiling never publicly readable |
| Financial protection | Browser cannot insert/update payment events or ledger; bad signatures, amount/currency mismatch and duplicate events fail; refund/settlement cannot exceed collected/available amount; ledger rows are immutable |
| Legal evidence | Published version cannot mutate; acceptance is immutable and tied to exact body/hash/version; obsolete version fails current-required gates |
| Private documents | Identity, bank, certificate originals and proofs have owner/staff policies; signed URLs are short-lived and purpose-scoped |
| Analytics | Direct identifiers and raw IP rejected; visitor values salted/hashed; retention deletion does not remove financial/audit evidence |
| Staging | `anon`, `authenticated` and ordinary service paths cannot access `emergent_staging`; no new exposed schema |

## Threats requiring implementation review

- Email-based account linking can cause takeover unless both source and Supabase email are verified and the user confirms the link.
- Broad “admin all” policies are inappropriate for role management, secrets and finance; new objects use named permission predicates.
- Security-definer functions must set `search_path`, revoke PUBLIC execute and grant only intended callers.
- Webhook and Cron endpoints need independent authentication, replay prevention and durable idempotency.
- Source audit identities are historical text references, not current authority.
- Attribution placeholder values must never satisfy reviewer/approver foreign keys.
