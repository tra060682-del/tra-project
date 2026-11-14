# Phase 6A shipping, certificates and private media

## Artist-led fulfilment

The existing shipment aggregate remains authoritative. The proposed extension records responsibility, packaging/dispatch/delivery/exception state, carrier and tracking references, dispatch/delivery timestamps and delivery confirmation. `shipment_events` is the audit timeline. The state helper prevents delivery before dispatch and supports exception recovery.

Collector views must expose only approved tracking status. Artists receive only fulfilment data for their own authorized sales. Intermediaries receive data only under active representation scope. Private addresses and contact details are not part of public or catalogue contracts. No courier API is integrated.

## Certificates of Authenticity

The existing certificate remains authoritative and gains issuer artist, version, hashed verification token, revocation timestamp/reason and private file reference. The artist remains the issuer. Administration may review or revoke but cannot silently substitute the issuer. Events preserve issue/version/revoke history.

The proposed public RPC accepts only a `tra_coa_` token carrying 256 bits of URL-safe randomness, hashes it in the database, and returns only reference, artwork, artist display name, issue date, version, status and revocation state. It returns no owner, contact, price, order or storage information. Public execution and the server flag remain disabled pending approval, rate limiting and security review.

## Private media

`private_media_assets` stores an owner, bounded purpose, opaque provider key, original metadata, SHA-256 digest, 25 MiB maximum, malware-scan status and revocation. It does not store public URLs. Access events record upload, scan, view, download and revocation. Direct authenticated insert is not granted; a future server upload initializer must re-authorize ownership, issue a short-lived signed upload, and finalize only after type/size/digest/scan checks.

The existing 26 rights-approved images remain in `public/media/heritage`. No unresolved source asset was copied or referenced. Private-media activation needs a Cloudinary authenticated/private or R2 signed-object design, malware scanning, retention and incident response approval.

