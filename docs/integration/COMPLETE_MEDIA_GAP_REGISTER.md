# Complete media gap register

## Boundary

All 49 exported files match `assets/IMAGE_MANIFEST.json`. The 26 Wikimedia/Public Domain/Creative Commons assets in `PHASE2_APPROVED_MEDIA.json` remain bundled under `public/media/heritage`. The other 23 remain outside the public tree. This register is provenance evidence, not a legal opinion.

| Source group | Files | Status | Main affected surfaces |
|---|---:|---|---|
| Wikimedia with recorded licence/credit | 26 | Approved and bundled | replacement/reference imagery across public design |
| Unsplash | 8 | Quarantined | source fallbacks, artworks 11–15/24, auctions 1/4, many articles |
| Emergent-hosted static | 10 | Quarantined | artworks 1–10 and 16–23, auctions 2/3/5–9, taxonomy covers, articles |
| Cloudinary | 5 | Quarantined; four reported invalid placeholders | seven UUID artworks, four auctions, three articles |

## Per-file rights-resolution register

| ID | File | Origin | Source usages | Status | Evidence required |
|---|---|---|---|---|---|
| MED-001 | `53435bdb48b451.jpg` | Unsplash | frontend fallback | Quarantined | original download/licence record, attribution and commercial-use review |
| MED-002 | `ee809abb1f7a8d.jpg` | Unsplash | artwork `art-012` | Quarantined | same plus artwork-owner publication approval |
| MED-003 | `2042c307e4b62d.jpg` | Unsplash | artworks `art-011`, `art-024`; auction `auc-01` | Quarantined | same plus auction reuse approval |
| MED-004 | `85bc1297739d59.jpg` | Unsplash | frontend fallback | Quarantined | original download/licence record |
| MED-005 | `81b5d621d05f9f.jpg` | Unsplash | 15 articles, artwork `art-015`, auction `auc-04` | Quarantined | per-use editorial/artwork provenance and attribution |
| MED-006 | `202ed81ecab6ae.jpg` | Unsplash | artwork `art-013` | Quarantined | source and artwork-owner approval |
| MED-007 | `db36cf6c8d81be.jpg` | Unsplash | artwork `art-014` | Quarantined | source and artwork-owner approval |
| MED-008 | `20f4b7d241cf87.jpg` | Unsplash | frontend fallback | Quarantined | original download/licence record |
| MED-009 | `fdc3f0f581f321.jpg` | Cloudinary demo | seven UUID artworks | Quarantined | replace invalid/demo content with owner-authorised originals |
| MED-010 | `cd790d4a72c9d7.png` | Cloudinary authenticated | one UUID artwork, four auctions | Quarantined | ownership, valid file, access/export and publication evidence |
| MED-011 | `2d3eaf2e58c95a.png` | Cloudinary | article `6b96…` | Quarantined | valid file and editorial rights |
| MED-012 | `0659a97a9613f6.png` | Cloudinary | article `465d…` | Quarantined | valid file and editorial rights |
| MED-013 | `767ebe59a5fa16.png` | Cloudinary | article `9ef8…` | Quarantined | valid file and editorial rights |
| MED-014 | `8b4a1334896bb5.jpg` | Emergent static | artwork `art-004`, auction `auc-08`, taxonomy | Quarantined | creator/owner licence, attribution, auction/taxonomy reuse |
| MED-015 | `b7128299332036.jpg` | Emergent static | article, artworks `art-001/016`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-016 | `64e279f589c543.jpg` | Emergent static | artworks `art-008/020`, auction `auc-05`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-017 | `93d8c2ae540ee4.jpg` | Emergent static | artworks `art-007/019`, auction `auc-03`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-018 | `964ba62264d7a9.jpg` | Emergent static | artworks `art-009/021`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-019 | `305df53d83d55d.jpg` | Emergent static | artworks `art-010/022`, auction `auc-06`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-020 | `43cf53525cc971.jpg` | Emergent static | artworks `art-006/018`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-021 | `23c8e0bde8152d.jpg` | Emergent static | article, artwork `art-002`, auction `auc-02`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-022 | `3997883106f6a4.jpg` | Emergent static | article, artworks `art-003/017`, auction `auc-07`, taxonomy | Quarantined | creator/owner licence and all-use approval |
| MED-023 | `8b7a78cc94319a.jpg` | Emergent static | artworks `art-005/023`, auction `auc-09`, taxonomy | Quarantined | creator/owner licence and all-use approval |

## Page impact

- **Catalogue/artwork details:** at least 23 source artwork IDs/UUID groups depend directly on quarantined files; this is a principal reason populated source parity cannot be achieved safely from the export alone.
- **Auctions:** all nine seeded auction references touch quarantined artwork/media.
- **Journal:** at least 18 article references use quarantined Unsplash/Cloudinary/Emergent files.
- **Homepage/fallbacks:** three Unsplash source fallbacks are unavailable; licensed heritage imagery may be used only where editorially approved, not as fabricated artwork content.
- **Taxonomy/collections:** several source category covers depend on quarantined Emergent-hosted images.

## Resolution acceptance

For each asset: identify rights holder, work/creator, source URL or original file, licence/contract, permitted commercial uses/territories/duration, required attribution, modification restrictions, and approver. Verify checksum, malware scan, alt text, metadata and target usage. Only then add it to an approved-media manifest and public storage. No unrelated stock substitution is acceptable.
