# Phase 6B.1 auction security and load testing

## Scope

PostgreSQL remains authoritative for real auction concurrency. `LocalAuctionLoadAdapter` is an isolated executable reference used only to stress request serialization and security decisions without touching any Supabase auction row.

The adapter serializes synthetic requests, stores request IDs exactly once, retains bidder maxima privately, applies deterministic maximum/priority ordering and opening/increment/reserve behavior, and rejects closed auctions, invalid values, ineligible identities, suspended accounts and every identity containing the Finance role.

## Results

Five load tests passed:

1. 200 simultaneous eligible bids serialized with the correct deterministic winner and price.
2. Duplicate request IDs were exactly-once.
3. Bids at the closing boundary were rejected.
4. Reserve-not-met behavior was preserved.
5. Finance and suspended identities were denied under concurrent execution.

These tests do not substitute for the rehearsed PostgreSQL bid RPC tests. Phase 3.5 already validated proxy-bid serialization, replay idempotency, maximum confidentiality, kill switch, conflicts, terminal lot immutability, close/audit and Finance prohibition in disposable PostgreSQL.

No live bid, winner selection, payment, settlement or rule change occurred. A real launch remains blocked by AUC-01, bidder/terms/legal approval, per-auction dual control, incident staffing, payment/refund/reconciliation readiness and production load/security rehearsal.

