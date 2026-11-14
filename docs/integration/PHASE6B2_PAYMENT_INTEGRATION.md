# Phase 6B.2 payment integration

## Implemented

Razorpay and Stripe test-mode adapters implement intent/order creation, retrieval, refund creation, refund retrieval and provider response validation. The registry selects exactly one provider per operation. Local simulation remains available for deterministic development.

### Security controls

- Integer minor units and ISO 4217 currency codes only.
- Server-side order reference, amount and currency verification.
- Stable idempotency keys; duplicate local operations return the original result.
- Stripe `Idempotency-Key`; Razorpay receipt/reference plus refund idempotency header.
- Stripe signatures validate timestamp plus raw body HMAC.
- Razorpay signatures validate the unmodified raw body; event identifiers provide deduplication and the application records receipt age.
- Provider timeouts and retry classifications are structured and credential-free.
- Browser redirects never mark an order paid.

Official contracts used: [Stripe PaymentIntents](https://docs.stripe.com/api/payment_intents), [Stripe webhooks](https://docs.stripe.com/webhooks/signature), [Razorpay Orders](https://razorpay.com/docs/api/orders/create/), and [Razorpay webhook validation](https://razorpay.com/docs/webhooks/validate-test/).

## Not active

No sandbox request was made. No webhook route exists. No merchant account, Connect account, payout, payment, refund or settlement was created. Completion still depends on PAY-01 through PAY-03 and REF-01 in the Phase 6A.5 register, the Phase 3/6A database migrations, an event-id store and audited callback endpoints.

## Sandbox prerequisites

Approve one provider; create its test account; install test credentials as development secrets; approve an HTTPS callback; define replay retention and rotation; provide synthetic order fixtures; execute create/retrieve/refund/webhook/reconciliation tests; record evidence; disable the flag after the test window.
