# Complete Emergent-to-Next.js parity audit review

## Outcome

The application is **not at complete visual or functional parity**. The current branch contains the latest safe integration history and the catalogue layout remediation, but public approved data are effectively empty, many source modules are simplified, and most commerce/privileged workflows are migration- or provider-gated. Prior phase-completion labels describe their scoped deliverables; they do not demonstrate complete product equivalence.

No application functionality, database, provider, production infrastructure, deployment or staged data was changed by this audit.

## Verified baseline

- Branch created: `integration/emergent-complete-parity-audit` from catalogue parity commit `8c328ef`.
- History: `8c328ef` descends from Phase 6B.2 documentation tip `e370d9b`, provider/security commits, Phase 6B.1, Phase 6A.5, Phase 6A, Phase 5, and earlier phases. No later integration branch functionality is missing.
- Emergent export: `EXPORT_MANIFEST.md` and `FILES.sha256` were previously verified **388/388**, zero missing/mismatched; source/tests remain authoritative.
- Source coverage: 37 declared routes, 24 page modules, 26 shared/component files, 214 business operations.
- Next coverage: 52 page routes, 17 component files and 9 server-action files inventoried.
- Browser evidence: 28 current Next surfaces × 3 widths = **84 local captures**; no automated horizontal overflow. Live Emergent access was unavailable, so only the previously approved live catalogue captures are live-to-live evidence. Other comparisons are source/reference based.
- Data: latest documented read-only baseline is 39 public tables; public artworks/media/artists/collections are zero. Staging remains 400 records/15 collections and private.
- Media: 26 approved files remain bundled; 23 remain quarantined.

## Gap count

| Severity | Count | Meaning |
|---|---:|---|
| P0 | 24 | Core product missing or unusable |
| P1 | 79 | Major visual or functional discrepancy |
| P2 | 18 | Important non-blocking discrepancy |
| P3 | 3 | Visual polish |
| **Total** | **124** | Stable IDs indexed in `COMPLETE_FUNCTIONAL_GAP_REGISTER.md` |

The count includes 20 consolidated functional-domain gaps covering all 214 operations, 24 visual gaps, 14 data gaps, 43 dashboard workflow gaps, and 23 individual media-rights gaps. It does not count each of the 210 non-equivalent operations as an additional gap, avoiding artificial double-counting.

## Critical findings

1. **Catalogue/content emptiness:** the local application correctly refuses private staging data, but zero public artworks/artists/media/collections makes the principal user journey unusable. Emergent showed 33 works while staging has 27; this must be reconciled, not fabricated.
2. **Global visual composition:** tokens are recognisably derived from Emergent, yet header/footer, homepage media/copy, section density, service pages, authentication and role dashboards remain materially different.
3. **Dynamic public pages:** routes exist for artwork, artist, collection, auction and journal details, but route existence is not parity; no authorised representative records demonstrate them.
4. **Operation coverage:** of 214 source operations, 1 is currently equivalent, 60 partial and 153 have no active equivalent. Many of the 153 are correctly blocked by unapplied security/commerce migrations or unapproved providers.
5. **Dashboard workflows:** all five shells exist, but complete source tab/action coverage is not present. Super Admin access changes, intermediary scope, commerce, private media and finance remain blocked at the correct security boundaries.
6. **Media:** 23 source assets block faithful artwork/auction/journal/taxonomy visuals. They may not be published or replaced with unrelated stock merely to improve screenshots.
7. **Source route gaps:** `/view-in-room`, `/verify`, `/verify/:number` and the source-specific bid guide/payment verification journeys have no direct active Next equivalent.
8. **Evidence limitation:** the Emergent host was inaccessible during this audit. Homepage evidence uses the verified disposable reference; catalogue evidence uses prior approved live captures. A final audit requires renewed live/reference capture access.

## Root causes

| Root cause | Consequence |
|---|---|
| Incomplete component port / generic Phase foundations | Source page-specific layouts and dashboard IA became simplified templates. |
| Empty approved public Supabase content | Populated visuals and data-driven journeys cannot be demonstrated. |
| Unapplied Phase 1/3/6A migrations | Multi-taxonomy, RBAC, representation and commerce enforcement are unavailable. |
| Intentional security restrictions | Live auction/payment/certificate/provider actions are correctly disabled, but remain functional gaps. |
| Media-rights quarantine | Exact source artwork, auction and journal imagery cannot be used. |
| Provider replacement/absence | Clerk UX differs; email/payment/storage/queues remain disabled. |
| Route/IA redesign during staged migration | Source URLs, tabs and combined account/admin modules differ. |
| Historical phase scope interpreted as product completion | Passing scoped tests validated foundations, not complete Emergent journeys. |

## Required approvals

1. Record-level 33/27 artwork reconciliation and approved staging-to-public content plan.
2. Rights decision for each of 23 quarantined files; no blanket approval.
3. Phase 3 RBAC/RLS rollout and secure initial Super Admin bootstrap.
4. Phase 1 catalogue/content structures that remain necessary; superseded drafts must stay excluded.
5. Phase 6A 22-table commerce migration and offer/reservation/order/refund/commission/settlement policies.
6. Clerk-to-Supabase identity matching rules and evidence source.
7. Certificate public disclosure, issuer/revocation and rate-limit policy.
8. Payment/email/private-storage/scanner/queue/monitoring sandbox providers and server-only credentials.
9. Auction preview content and, separately, any future legal/financial launch controls.
10. A later production release plan, environment-label resolution, backup/rollback evidence and explicit deployment approval.

## Exact implementation sequence

1. Lock automated visual evidence and restore source header/footer/navigation.
2. Reconcile homepage.
3. Complete catalogue/detail UI while data/media approvals proceed in parallel.
4. Complete artists/collections, then auctions and Journal.
5. Complete services/legal/auth journeys.
6. Apply no database change until Phase 3 review/approval; then validate RBAC before dashboard mutations.
7. Reconcile Super Admin/Admin, Artist, Intermediary and Collector in that order, using source workflows and honest gates.
8. Apply commerce/provider work only after its separate approvals.
9. Run final route-by-route three-width, 214-operation, security, accessibility and build verification with authorised representative data.

## Readiness decision

Ready for **approved, non-database visual remediation** and local test work. Not ready for staged-data promotion, database application, provider activation, commercial activation, production deployment, merge to main, or a claim of complete parity.

Stop point: audit complete; remediation requires explicit approval.
