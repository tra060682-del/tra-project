# Phase 6A notifications

## Model

Notifications are user-owned records with category, subject, bounded body/link, retry-safe dedupe key and read timestamp. Preferences are keyed by user/category and default email off. Delivery attempts are separate records with channel, unique idempotency key, provider reference, attempt count, next attempt and failure detail.

Supported categories are artist onboarding, artwork submission/approval/rejection, buyer enquiry, offer/counteroffer, order, shipping, certificate and account security. The application helper validates the vocabulary and resolves duplicate preference updates deterministically.

## Security and delivery

RLS exposes only the active user's notification and preference records. Mark-read affects only caller-owned rows. Notification creation and delivery are privileged server operations; client code cannot claim or forge provider delivery. A future worker must lock a pending delivery, send once using its idempotency key, record the provider result, and back off safely.

Outbound email is disabled. No email provider, API key, template, queue or retry worker was added. In-app persistence is also disabled until the migration is approved. Account-security communications must not be suppressible where legally or operationally required; that policy remains for approval.

## Activation dependencies

- approve categories, mandatory notices, consent and retention;
- select the transactional provider and sender identity;
- approve templates and localization;
- configure server-only secrets and bounce/complaint callbacks;
- deploy a monitored retry worker;
- rehearse deduplication, retries and revocation;
- enable in-app and email flags independently.

