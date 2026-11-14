# Complete parity remediation roadmap

## Governing rule

The verified Emergent source defines design, information architecture, interactions and workflow intent. Next.js, Supabase Auth/RLS/RPC and Cloudflare controls remain authoritative for security and deployment. A source action that is insecure or commercially unapproved is reproduced visually only as an accurately disabled state until its secure contract is approved.

## Recommended sequence

| Order | Workstream | Primary gaps | Can proceed without DB change | Blocking approvals/dependencies | Complexity | Acceptance evidence |
|---:|---|---|---|---|---|---|
| 0 | Baseline and test harness | all | Yes | none | S | Pin branch/build, retain 388/388 checksum evidence, automate 1440/768/390 source-vs-Next captures. |
| 1 | Shared header, footer, navigation | VIS-001/002/022 | Yes | none | M | Route-complete desktop/mobile nav; exact source order/dimensions/focus; no broken links. |
| 2 | Homepage composition | VIS-003/004 | Mostly | rights-approved media/content | L | Source section order/copy/CTA/typography at three widths; blocked dynamic modules honest. |
| 3 | Catalogue and artwork detail | VIS-005–007, DATA-001–005, FUNC-009 | UI yes; real content no | content promotion, taxonomy, media rights | XL | Populated authorised three-column gallery, source filters/sorts, detail gallery and enquiries; public RLS tests. |
| 4 | Artists and collections | VIS-008/009 | UI yes; real content no | identity/content promotion, collection schema | L | Populated source-equivalent directory/profile/index/detail and relationship tests. |
| 5 | Auction Lobby/detail | VIS-010, FUNC-004 | Preview UI yes | preview content; launch/legal/finance approval for operations | L | Source visual preview; all live controls server-disabled; concurrency tests retained. |
| 6 | Art Journal | VIS-011, FUNC-011 | UI yes | editorial/media approval, content schema | L | Source index/article layouts and CMS states with authorised stories/images. |
| 7 | Advisory/service/about/authenticity/legal | VIS-012/013, FUNC-012/019 | Mostly | versioned legal/data and email for full workflow | L | Exact source content/forms/feedback; real intake status; no false delivery. |
| 8 | Authentication journeys | VIS-014, FUNC-015/016 | UI yes | identity-link and bootstrap approvals for privileged states | M | Source visual parity using Supabase; registration/verification/reset/session tests. |
| 9 | Dashboard shell and Super Admin/Admin | VIS-015/016, DASH-001–018 | Layout/read-only modules yes | Phase 3 migration/bootstrap; content/commerce migrations | XL | Role-specific source IA; each control either persists securely or is accurately disabled. |
| 10 | Artist Studio | VIS-017, DASH-019–028, FUNC-020 | UI/onboarding core yes | media/content/commerce schemas | XL | Exact source form/status/tab coverage; ownership/legal/media/commerce tests. |
| 11 | Intermediary | VIS-018, DASH-029–034, FUNC-010 | UI/profile yes | Phase 3 scoped RLS/RPC and policy | L | Consent/scope/history parity; immediate revoke/expiry and cross-artist tests. |
| 12 | Collector account | VIS-019, DASH-035–043, FUNC-006 | UI yes | Phase 6A migration and commercial policies | XL | Wishlist/bag/offers/orders/certificates/notifications with owned data or honest gates. |
| 13 | Providers and operations | FUNC-008/013/014/017/019 | Local simulations yes | provider/sandbox/infrastructure approvals | XL | Verified webhook/email/storage/queue diagnostics; no production activation. |
| 14 | Media resolution/content reconciliation | MED-001–023, DATA-001–014 | Rights register yes | legal/product/content approvals | L–XL | 33/27 reconciliation, approved manifests, record-level promotion plan and checksums. |
| 15 | Final parity verification | all remaining | Yes after dependencies | approved representative data/accounts | L | Side-by-side three-width evidence for every route; 214-operation journey matrix; WCAG/security/build suites. |

Complexity: S ≤3 engineer-days, M 4–8, L 2–4 engineer-weeks, XL 4–8 engineer-weeks. These are planning ranges, not delivery commitments. Sequential effort is approximately **30–48 engineer-weeks**; parallel public, dashboard, data/media and test work can reduce elapsed time after approvals.

## Safe development-only work now

- Shared header/footer/navigation and source-faithful public layouts using authorised heritage media and honest empty states.
- Component and dashboard visual shells, forms, validation schemas and disabled-state placement.
- Supabase-provider auth visual reconciliation without Clerk migration.
- Local synthetic provider adapters, webhook/signature fixtures, email capture, storage quarantine, job runners and monitoring redaction tests.
- Automated screenshot, accessibility, responsive and source-contract tests.
- Record-level data/media reconciliation plans without querying staging from the app or promoting rows.

## Work that must wait

- Role/status/invitation/intermediary enforcement: Phase 3 migration and Super Admin bootstrap approval.
- Real catalogue population: identity, rights, taxonomy and record-level promotion approval.
- Offers/reservations/orders/ledger/settlements/notifications: Phase 6A migration and commercial policies.
- Provider network traffic, email, private R2/queues/scanner: account, credential, data-processing and sandbox approval.
- Public certificate verification: disclosure contract/migration/security approval.
- Live bidding/payments/settlements: separate legal, financial, operational and production approvals.

## Definition of done per task

1. Cite the exact Emergent source component/operation and Next target.
2. Preserve server authorization and fail-closed flags.
3. Demonstrate authorised persistence or label the action disabled.
4. Capture Emergent/Next at 1440, 768 and 390 with representative authorised data.
5. Test keyboard/focus/overflow, validation, errors and relevant permission/ownership boundaries.
6. Update the stable gap ID to closed with evidence; do not close based on route existence.

## Release gates

Public visual remediation can be reviewed independently. Database application, content promotion, provider connectivity, production deployment and commercial activation each require separate approvals and rollback/runbook evidence. No single “parity approval” authorises those changes.
