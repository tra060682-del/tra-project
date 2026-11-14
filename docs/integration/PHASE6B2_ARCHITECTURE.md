# Phase 6B.2 external integration architecture

## Outcome

Phase 6B.2 adds provider-specific adapters behind the Phase 6B.1 interfaces. All external modes remain disabled. No network probe, account creation, infrastructure change, database migration, customer email, payment, refund, upload, queue message or deployment was performed.

## Runtime boundaries

| Capability | Providers prepared | Default | Activation boundary |
|---|---|---|---|
| Payments/refunds | Razorpay, Stripe | disabled/local simulation | sandbox mode, test credentials, category flag and `phase6b2-sandbox-approved` |
| Transactional email | Resend, Amazon SES | disabled/local capture | sandbox mode, allowlist, verified sender, flag and approval |
| Private documents | Cloudflare R2 binding | disabled/local memory | private development bucket binding, signing secret, flag and approval |
| Malware scanning | authenticated HTTPS scanner | disabled/local synthetic | selected scanner, quarantine workflow, flag and approval |
| Background work | Cloudflare Queues contracts | disabled/local runner | development bindings, consumer, DLQ, flag and approval |
| Schedules | Cloudflare Cron contract | disabled/deterministic clock | approved development triggers and overlap controls |
| Monitoring | local structured logs | local only | approved external sink and data-processing review |

Provider construction is centralized in `provider-registry.ts`. Business code depends on provider-neutral interfaces. Adapters accept injected transport/bindings, which makes tests deterministic and ensures no test contacts a provider.

## Safety properties

- Provider configuration is server-only; no `NEXT_PUBLIC_` provider secrets exist.
- A configured provider is not considered operational. A sandbox requires an explicit activation reference and recorded verification.
- Payment state changes require verified provider evidence and exact order, amount and currency matching.
- Private files remain quarantined until a trusted clean scan result.
- Queue messages carry stable idempotency and correlation identifiers.
- The existing Cloudflare configuration remains unchanged and contains no R2, Queue or Cron binding.
- The Phase 6A 22-table proposal remains unapproved and unapplied.

## Data flow

`authorised server operation -> domain validation -> provider registry -> selected adapter -> injected provider transport -> redacted audit/health result`

Provider callbacks and private-download endpoints are intentionally absent. They must be added only after schema, provider, endpoint and abuse-control approval.
