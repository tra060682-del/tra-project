# Phase 6A orders and payment foundation

## Order aggregate

The existing `sales` table remains the order aggregate. The proposal adds buyer identity, source kind, offer/reservation linkage, currency, exact price/tax/shipping/fee/payable snapshots, fulfilment status, cancellation metadata and an immutable JSON price snapshot. Existing rows retain compatible defaults; no historical price is recalculated.

The application currently reads real authorized sale, shipment, settlement, certificate and payment-link rows. New write transitions remain disabled. Collector reads are `buyer_user_id` scoped; artist reads follow artwork ownership; intermediary access needs active consent and scope; operational and finance access use named permissions.

## Payment foundation

Provider-neutral tables separate intent, attempt and incoming event. Idempotency keys are unique, provider event IDs are unique, callback signature verification is explicit, and the immutable payload digest is retained. No intent creator, payment provider SDK, webhook route, credential, or real request is active in Phase 6A.

An order may become paid only after a future server callback verifies signature, replay key, provider/order reference, exact amount, currency and current state in one database transaction. Browser redirects are never payment evidence.

## Refunds

The request RPC is restricted to `payments.manage`, locks the sale, verifies refundable state, ensures requested plus pending/paid refunds do not exceed the recorded gross amount, and assigns an idempotency key. Provider execution remains absent and disabled.

## Activation checklist

1. Approve the migration and Phase 3 dependency.
2. Select a provider and obtain test-only server credentials.
3. Approve webhook signing, replay window and idempotency retention.
4. Approve tax, buyer premium, cancellation and refund policy.
5. Add provider adapter and background retry worker with monitoring.
6. Execute failure/replay/reconciliation tests in provider sandbox.
7. Record a separate activation approval and enable only the relevant server flags.

