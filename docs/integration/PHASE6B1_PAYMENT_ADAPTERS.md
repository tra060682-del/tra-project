# Phase 6B.1 payment and refund adapters

## Contracts

`PaymentGateway` defines create/retrieve intent and request/retrieve refund. `LocalPaymentGateway` stores synthetic records in memory, uses exact integer minor units, validates three-letter currency and stable idempotency keys, and never performs network I/O. Repeating a creation/refund idempotency key returns the original synthetic record.

The local state model supports `created`, `requires_action`, `processing`, `succeeded`, `failed`, `cancelled`, `partially_refunded` and `refunded`. Verified events enforce state ordering. A refund remains `requested` until an authenticated provider-style event confirms success. Requested, processing and successful refund amounts all reserve refundable capacity, preventing concurrent over-refund.

## Webhook verification

The verification contract signs `timestamp.rawBody` using HMAC-SHA256 and compares signatures in constant time. It rejects missing/invalid signatures, invalid/expired timestamps, modified payloads and malformed events. The adapter then rejects unknown payments, wrong order reference, amount/currency mismatch, invalid terminal ordering and duplicate event IDs. Default timestamp tolerance is five minutes.

Tests use only `phase6b1-test-signing-key` and synthetic payloads. `signWebhookTestOnly` is a fixture helper, not a production signing facility. No `/api/payments/webhook` route exists.

## Refund and reconciliation behavior

- Full and partial refund requests reference a successful synthetic payment.
- Currency must match the payment.
- Requested plus in-flight plus completed refunds cannot exceed captured value.
- Provider confirmation, not application request, changes completion state.
- Financial reconciliation separately compares payment, refund, ledger and settlement evidence.

## Activation requirements

Before a real adapter: approve PAY-01/02/03 and REF-01 in the Phase 6A.5 register; select the provider; configure sandbox credentials as server-only secrets; implement provider-specific signature rules; use transactional event/RPC persistence; configure replay retention and secret rotation; complete sandbox failure/reconciliation tests. Environment variables alone cannot activate the adapter.

