# Phase 6B.2 transactional email integration

## Implemented

Resend and Amazon SES v2 adapters reuse the Phase 6B.1 email contract. Nineteen branded HTML/plain-text templates cover the required eighteen product events plus the existing password-reset notification. Supabase Auth remains responsible for verification and reset emails.

The adapters enforce recipient syntax, consent/preferences, suppression, test-recipient allowlisting, stable idempotency, retry-safe provider responses and server-only configuration. An accepted provider response is recorded as `accepted`, not delivered.

Resend uses its HTTPS send endpoint and idempotency header. SES uses a least-privilege identity and AWS Signature Version 4 for `SendEmail`. Official references: [Resend send email](https://resend.com/docs/api-reference/emails/send-email), [Resend idempotency](https://resend.com/docs/dashboard/emails/idempotency-keys), [SES v2 SendEmail](https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_SendEmail.html), and [SES sandbox restrictions](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html).

## Not active

No account, domain, DNS record, sender identity, suppression callback or provider credential was configured. No email was sent. Local capture never claims delivery.

Real delivery requires approval of MSG-01/02, a provider/DPA, sender domain and DKIM/SPF/DMARC changes, a test allowlist, delivery callback design, retention policy and an approved sandbox window.
