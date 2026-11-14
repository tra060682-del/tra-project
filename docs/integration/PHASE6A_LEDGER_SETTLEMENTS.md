# Phase 6A ledger, settlements and commissions

## Ledger

`financial_ledger_entries` is an append-only double-entry journal. A transaction ID groups entries; idempotency prevents duplicate posting; each entry records account, direction, exact minor units, currency and source references. The posting RPC rejects empty or unbalanced batches. `UPDATE` and `DELETE` raise `FINANCIAL_RECORD_IMMUTABLE`; authenticated users have no insert grant. Corrections require a new compensating transaction.

The disposable rehearsal proved balanced posting succeeds, unbalanced posting fails, and posted entries cannot be changed or deleted. This proves the draft in isolation only; the development database has not received these controls.

## Settlements

The existing `settlements` aggregate is extended with exact gross, platform fee, intermediary commission, adjustment, artist payable, currency, hold reason and provider-neutral reference. `settlement_events` supplies status history. Phase 6A never creates a payable obligation from preview data and never initiates a transfer.

## Intermediary commission

A commission row must reference both a sale and the representation agreement. `rule_snapshot` freezes the consented rule as of entitlement; the amount is exact minor units and unique per sale/representation. Visibility is limited to settlement staff or the owning intermediary profile. View access alone never grants entitlement.

## Reconciliation

Operations can inspect proposed payment, refund, settlement, commission and exception projections. Reconciliation must balance payment evidence, ledger transactions, sale totals, refunds and settlement totals. Exceptions are explicit records, not silent status edits.

## Pending decisions

Legal/product approval is required for platform fee and tax treatment, commission rounding, adjustment authority, hold/release rules, representation changes after sale, refund allocation, settlement cadence, bank-data processor, retention and dispute handling. Until then settlements, commissions and provider actions remain disabled.

