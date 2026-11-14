# Phase 5 Artist Studio

`/artist` now uses the shared responsive dashboard shell and provides real profile/onboarding state, versioned legal acceptance, artwork submission, owned artwork status, representation consent, auction consideration, and authorised enquiry/sale/settlement summaries.

Current working persistence:

- `save_artist_onboarding`, `submit_artist_onboarding`, `accept_artist_legal_version`.
- `submit_artist_artwork` using the authoritative baseline fields and declaration.
- `respond_to_representation` for explicit consent or rejection.
- Existing auction-consideration submission; it does not activate bidding.

Limits are explicit. The current safe artwork RPC submits directly; a dedicated audited draft-update RPC is still needed for full draft editing. Secure image upload is blocked until a server-signed Cloudinary/R2 policy is approved. Artists cannot approve or publish their own work. Representation revocation remains server-gated until the Phase 3 enforcement migration is applied. Financial records are read-only and never imply payment.

