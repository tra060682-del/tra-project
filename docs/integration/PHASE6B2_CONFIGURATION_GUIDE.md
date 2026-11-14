# Phase 6B.2 configuration and rollback guide

This guide authorizes nothing. Account creation, credentials, DNS, infrastructure, connectivity, migration, deployment and activation each require separate approval.

## Common procedure

1. Approve the provider and relevant Phase 6A.5 decision.
2. Create a development/sandbox account owned by the organisation; enable MFA and two administrators.
3. Issue least-privilege test credentials and store them as development Worker secrets, never Git or client variables.
4. Configure the provider-specific variables listed in `.env.example`; keep mode `disabled`.
5. Review diagnostics: it must show configured but disabled.
6. Approve a bounded test window and test recipients/resources.
7. Set category mode to `sandbox`, the category flag to `true`, and activation reference to `phase6b2-sandbox-approved` server-side.
8. Run synthetic validation, record event IDs and safe evidence, then return the mode to `disabled`.
9. Rotate/revoke test credentials if exposed and remove unused bindings.

## Payments

Create one Stripe test-mode or Razorpay test-mode account, obtain test secret and webhook signing secret, and approve an HTTPS callback before adding a route. Configure only one `PAYMENT_PROVIDER`. Test create/retrieve, signed callbacks, duplicates, wrong amount/currency, refund and reconciliation. Disable by setting `PAYMENT_MODE=disabled`, setting the flag false, removing the callback and revoking test keys.

## Email

Create Resend or SES sandbox access. Verify a development sender domain and configure SPF/DKIM/DMARC only after DNS approval. SES sandbox recipients must also be verified; Resend must use the approved test allowlist. Test HTML/text, suppression, duplicate prevention, bounce/complaint callbacks and delivery status. Disable mode/flag, remove callbacks and revoke the API/IAM identity.

## R2 and scanning

Create a development-only private bucket with no public domain. Bind it only to the development Worker using the approved binding name. Store the access signing secret in Worker secrets. Configure retention/lifecycle and CORS only if a direct-upload design is approved. Connect the approved scanner, verify quarantine-first behavior with synthetic files, and test revocation. Disable mode/flag, remove the binding, revoke credentials and retain/delete fixtures per the approved policy.

## Queues and schedules

Create development queues and DLQ after approving topology. Add producer/consumer bindings only to the development Worker, configure retry/concurrency, then validate duplicates, backoff and DLQ. Add Cron Triggers only after schedules and overlap policy are approved. Disable producer/consumer flags, remove triggers/bindings and drain or delete synthetic jobs using the approved retention procedure.

## Monitoring

Select a processor only after DPA, region and retention review. Configure a development project and scoped ingest token, verify redaction with synthetic records, then alert to approved test recipients. Disable export first, revoke token second, retain/delete test telemetry per policy.

Never copy development credentials to production. Production activation is a separate Phase 7 release decision.
