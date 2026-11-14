# Phase 6B.2 Cloudflare Queues and schedules

## Prepared

The Queue producer validates activation, serializes versioned jobs, carries correlation and idempotency keys, and calculates delivery delay. The consumer acknowledges completed duplicates, applies exponential retry, and stops retrying at the job limit. Deterministic scheduled-job contracts cover offers, reservations, notifications, reconciliation, certificates and health checks.

Proposed development bindings are `TRA_EMAIL_QUEUE`, `TRA_NOTIFICATION_QUEUE`, `TRA_COMMERCE_QUEUE` and `TRA_DEAD_LETTER_QUEUE`. These names are placeholders until infrastructure approval. The committed Worker configuration was deliberately not changed.

Official references: [Cloudflare Queue producers](https://developers.cloudflare.com/queues/configuration/javascript-apis/), [consumer acknowledgement/retry](https://developers.cloudflare.com/queues/configuration/batching-retries/), [dead-letter queues](https://developers.cloudflare.com/queues/configuration/dead-letter-queues/), and [Cron Triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/).

## Before activation

Approve queue topology, retention, max attempts, DLQ owner, consumer concurrency, cost limits, data classification and Cron expressions. Create development-only resources, bind only the development Worker, exercise duplicates/retries/DLQ/overlap, and remove or disable bindings after the validation window. No queue or Cron was created or invoked in this phase.
