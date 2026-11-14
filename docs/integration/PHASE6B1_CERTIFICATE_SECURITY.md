# Phase 6B.1 certificate verification security

## Implementation

Certificate tokens use the existing `tra_coa_` prefix plus 32 bytes of cryptographic randomness encoded as 43 URL-safe characters. Only SHA-256 token hashes are used for lookup. The local verifier checks token shape, applies a per-client fixed-window rate limit, records a digest prefix/outcome audit event and returns a filtered public projection.

The public projection contains only reference code, artwork ID, artist display name, issue date, version, status and explicit revocation. Tests prove that buyer identity, artist contact details, payment/settlement references and private file keys cannot appear.

Unknown/invalid tokens return generic absence; rate-limit exhaustion fails closed. Revoked certificates remain verifiable as revoked rather than disappearing. The artist remains the issuer; administrative review cannot rewrite issuer identity.

## Current boundary

All records are synthetic and in memory. The public page remains disabled, no RPC migration was applied and no public verification route/action was added. Local token generation and lookup do not authorize certificate issuance.

Activation requires CERT-01 approval of disclosure fields, evidence and issuer wording, revocation/appeal, token delivery/rotation, cache behavior, edge/application rate limits, monitoring and incident response. Then the disclosure-safe database RPC must pass the isolated and environment-specific security suite before the server flag is considered.

