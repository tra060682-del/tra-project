# P0 public website parity review

Date: 2026-11-14  
Branch: `integration/emergent-p0-public-parity`  
Baseline: `integration/emergent-complete-parity-audit` at `d43c866`, with Phase 6B.2 (`e370d9b`) and catalogue parity (`2521d90`) in ancestry

## Outcome

The public shell and priority discovery journey now follow the authoritative Emergent source rather than the interim Next.js interpretation. This work did not alter Supabase, migrations, authentication/RBAC, Cloudflare infrastructure or external-provider activation.

Resolved gap IDs: **VIS-001, VIS-002, VIS-003, VIS-004, VIS-006, VIS-022**.  
Partially resolved because approved production data is absent: **VIS-005, VIS-007, VIS-008, VIS-009, FUNC-009**.

## Implemented pages and components

- Shared header: Emergent menu taxonomy, seven desktop dropdowns, keyboard/focus behaviour, search panel, account/wishlist actions and nested responsive menu.
- Shared footer: Collect, Services, Artists and tRA columns; source product statement; contact/legal links; accurate test-environment status.
- Homepage: authoritative hero copy and CTA hierarchy, commitments, featured works, pledge, discovery categories/subjects, collections, artists, artforms, auction promotion, five-step collecting journey, advisory, artist programme, commissions, Journal and disabled newsletter sections.
- Artwork catalogue: existing catalogue-parity implementation preserved, including category navigation, multi-select facets, counts, URL state, sorting, pagination, mobile filter drawer and three-column desktop layout.
- Artwork detail: thumbnail-ready gallery, modal zoom, metadata, price/availability, enquiry/offer entry points, narrative, artist section, certificate disclosure and related works.
- Artists: source-style directory heading, search, view tabs, refine links, six-column portrait presentation, editorial profile, enquiry and commission entry points.
- Collections: feature-led listing, narrative cover treatment, collection detail header, ordered work grid and refinement link.

## Data and media boundary

Production pages query only approved public contracts. No staged data is read or promoted. When no qualifying data exists, pages show source-proportioned empty states rather than invented records.

For visual verification only, `?preview=approved-media` enables non-production fixtures on artworks, artwork detail, artists and collections. The fixture:

- returns no records when `NODE_ENV=production`;
- uses only the 26 files in the approved media register;
- is no-index;
- labels every record as a development reference and not inventory;
- provides no purchase, offer or enquiry success path;
- never queries `emergent_staging`.

The 23 unresolved Emergent assets remain quarantined and are not present in public deployment directories.

## Validation results

| Check | Result |
|---|---|
| Next.js type generation and TypeScript | PASS |
| Unit tests | **106/106 PASS** |
| Integration tests | **64/64 PASS** (includes 5 new P0 source/security assertions) |
| Security tests | **15/15 PASS** |
| Playwright regression suite | **69/69 PASS** |
| P0 browser journey | **31/31 PASS** |
| Catalogue browser journey | **19/19 PASS** |
| Responsive widths | PASS at 1440px, 768px and 390px |
| Horizontal overflow | 0px on tested public routes at 768px and 390px |
| Next.js production build | PASS, 53 static/dynamic pages generated |
| vinext compatibility | PASS, 100% (15 supported, 0 issues) |
| Cloudflare development environment validation | PASS with non-secret placeholder publishable configuration |
| Credential pattern scan | PASS; no live-key patterns |
| Approved-media boundary | PASS; 26 public files, 0 quarantine files under `public/` |

The Cloudflare validation was run in validate-only mode. No Worker build was deployed and no binding or infrastructure was changed.

## Security preservation

Server authentication, account landing routes and logout remain sourced from the Phase 3 authorization implementation. Hidden navigation is not used as an authorization boundary. Public fixtures cannot activate commerce, bidding, certificate verification or delivery integrations. Existing Phase 3–6B.2 security tests remain green.

## Completion assessment

The approved non-destructive P0 public corrections are implemented. Complete product parity is **not** claimed: public data reconciliation, auction and Journal parity, authentication-shell parity, 23 media-rights decisions and dashboard work remain open. See `P0_PUBLIC_REMAINING_GAPS.md`.
