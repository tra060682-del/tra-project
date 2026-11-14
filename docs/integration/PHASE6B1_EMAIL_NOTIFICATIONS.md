# Phase 6B.1 email and notifications

## Templates

The local renderer provides responsive HTML and plain text for 16 events: welcome/account verification, artist onboarding, artwork submission/approval/rejection, enquiry confirmation, offer, counteroffer, order, payment, shipping, certificate, invitation, password-reset notification, suspension and security alert.

Templates use the approved ivory/near-black/antique-gold tRA identity, a language declaration, viewport metadata, semantic headings, readable text, escaped user content and explicit security wording. Supabase Auth remains authoritative for actual verification and password reset; these application templates do not send duplicate Auth messages.

## Local delivery

`LocalCaptureEmailGateway` validates normalized recipient syntax, records messages in memory, labels delivery `captured` and `simulated`, and deduplicates by idempotency key. It never claims external delivery. Suppressed recipients remain suppressed. Optional email honors preferences; a security event preserves only the channels explicitly assigned by the approved event policy and does not invent an external channel.

`LocalNotificationDispatcher` resolves in-app/email channels, applies preferences for normal messages, deduplicates per event/channel and records simulated deliveries. It has no push or messaging provider.

## Future outbox

The production design remains transaction -> notification/outbox row -> leased worker -> versioned render -> idempotent provider call -> signed delivery callback -> retry/dead-letter/audit. Retryable and permanent failures must be distinguished. Sensitive data must not appear in subjects or logs.

Activation requires MSG-01/02 approval, provider/DPA selection, sender-domain and DNS approval, server-only token/callback secret, mandatory-category/consent policy, templates, retention, queue monitoring and bounce/complaint handling. No provider or DNS was configured.

