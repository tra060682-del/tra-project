# Phase 6B.1 financial reconciliation

## Contract

`reconcileFinancials` compares synthetic orders, verified successful payments, successful refunds, ledger entries, artist settlement and intermediary commission values. It detects:

- missing and duplicate successful payment;
- amount and currency mismatch;
- refunds exceeding payment;
- debit/credit imbalance;
- artist settlement mismatch;
- intermediary commission mismatch.

Issues carry a stable code, order reference, bounded detail and warning/critical severity. Clean evidence returns `ok: true`; any issue returns `ok: false`. The function does not mutate records, call a provider or correct finance automatically.

## Operational design

Future reconciliation should run after verified callbacks and on a scheduled recovery pass. It must compare provider evidence to immutable order snapshots, refund records, append-only ledger transactions and settlement/commission snapshots. Exceptions go to the operational queue with correlation/provider references and segregation-of-duties controls. Corrections use provider-confirmed state and compensating ledger entries, never silent updates.

Provider polling may recover missing callbacks but cannot weaken signature/idempotency checks. Daily totals must be grouped by currency and provider account. Banking/payout reconciliation is separately approval-gated.

Activation requires PAY-02/03, REF-01, SET-01, COM-01 and OPS-01 decisions, the Phase 6A schema, approved provider adapters, scheduled jobs, alert routing, retention and finance ownership. All Phase 6B.1 records were synthetic.

