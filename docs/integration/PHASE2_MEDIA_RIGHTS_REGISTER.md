# Phase 2 media rights register

## Decision

The Emergent image export contains 49 files and all 49 match `assets/IMAGE_MANIFEST.json`. Phase 2 bundles only the 26 files whose export metadata includes a specific licence and source attribution. The remaining 23 files are retained in the verified Emergent source archive but are not copied into the publishable Next.js `public` tree.

| Source group | Files | Phase 2 status |
|---|---:|---|
| Wikimedia Commons with Public domain, CC0, CC BY, or CC BY-SA metadata | 26 | Bundled locally; attribution retained |
| Unsplash | 8 | Quarantined pending per-image provenance review |
| Emergent-hosted static media | 10 | Quarantined; ownership evidence absent |
| Cloudinary | 5 | Quarantined; four files are invalid placeholders and ownership evidence is absent |

The reusable media registry exposes eight public-domain/CC0 references in the design preview. All image components require meaningful alt text, provide source credit, and may render a keyboard-dismissible zoom dialog. Contemporary artwork publication remains governed by the existing approved-media database workflow.

## Licence inventory

| Licence | Files |
|---|---:|
| Public domain | 7 |
| CC0 | 1 |
| CC BY 3.0 | 1 |
| CC BY-SA 3.0 | 7 |
| CC BY-SA 4.0 | 10 |

This register records source metadata; it is not a legal opinion. Any commercial campaign or modification of attribution-sensitive material still requires final rights review.

The complete per-file checksum, credit, licence, and source register for the 26 bundled assets is preserved in [`PHASE2_APPROVED_MEDIA.json`](PHASE2_APPROVED_MEDIA.json).
