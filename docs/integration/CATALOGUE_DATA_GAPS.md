# Catalogue data gaps

## Read-only evidence

On 2026-11-14, the linked project `ocstvctvmychromkcurw` was inspected with the Supabase CLI table-statistics command. This was read-only. The CLI labels the linked target `tra-development`; its target metadata also reports environment `production`, which is an environment-label discrepancy to resolve before any future mutation.

| Store | Object | Estimated rows | Catalogue consequence |
|---|---|---:|---|
| `public` | `artworks` | 0 | No public cards |
| `public` | `artwork_media` | 0 | No approved catalogue media relationships |
| `public` | `artist_profiles` | 0 | No public artist attribution relationships |
| `public` | `taxonomies` | 2 | Incomplete catalogue facets |
| `public` | `collections` | 0 | No public collection membership |
| `emergent_staging` | `artworks` | 27 | Private staging only; not queried or promoted |
| `emergent_staging` | `artists` | 13 | Private staging only |
| `emergent_staging` | `taxonomy_terms` | 85 | Private staging only |
| `emergent_staging` | `id_map` | 400 | Completed staging import remains untouched |

The live Emergent preview reported 33 works. The 33-to-27 difference is a source-versus-staging discrepancy, not a Next.js rendering bug. No attempt was made to reconcile it by copying live data.

## Why the catalogue was empty

The prior page correctly required published records, but its empty state obscured a second issue: it had replaced the Emergent category/facet/gallery design with a compact search/artist/budget form. The zero-card result is caused by public data availability; the material design difference was caused by an incomplete component port. Both are now distinguished.

The public reader requires all of the following:

1. an artwork row with `status = published`;
2. an approved and public artist relationship enforced by existing RLS;
3. at least one `artwork_media.is_approved = true` row for an image;
4. optional current taxonomy foreign keys for category, medium, style, and subject;
5. an authorized final price before INR is displayed.

## Unapplied dependencies

The baseline can represent one category, medium, style, and subject. Emergent supports multi-valued subjects, artforms, styles, collections, and colours. Full parity for those relationships depends on the unapproved Phase 1 `artwork_taxonomies` design (including the `artform` taxonomy enum/check extension), publication review, RLS, and migration rehearsal. This work did not apply that draft.

An approved public popularity aggregate is also required before “Most viewed” can be enabled. Raw private analytics events must not be exposed to anonymous clients.

## Media boundary

The Phase 2 export contains 49 files:

- 26 licensed Wikimedia/Public Domain/CC files remain bundled and checksum-registered.
- 8 Unsplash files remain quarantined pending per-image provenance review.
- 10 Emergent-hosted files remain quarantined because ownership evidence is absent.
- 5 Cloudinary files remain quarantined; four are invalid placeholders and ownership evidence is absent.

No quarantined asset was copied, imported, linked, or published by this phase.

## Activation path

Real catalogue population requires a separately approved content migration, not a UI change: reconcile the 33/27 source count, approve artist identities and attribution, approve every artwork/media right, map taxonomy relationships, satisfy publication requirements, test public RLS, and then promote only explicitly approved records in an auditable transaction. The existing 400-record staging import must not be repeated.
