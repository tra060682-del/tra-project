# Phase 6B.1 background and scheduled jobs

## Local job runner

`LocalJobRunner` supports notification, email, offer/reservation expiry, payment/refund reconciliation, certificate, media and shipping jobs. Enqueue is idempotent. Due jobs execute deterministically, transient failures use bounded exponential or explicit backoff, permanent/exhausted failures enter an inspectable dead-letter collection, and status/attempt/error evidence is retained.

The runner is in-memory and test-only. It has no Cloudflare Queue binding, network transport or database consumer and cannot execute against development or production records.

## Scheduler

`DeterministicScheduler` models offer expiry, reservation expiry, notification retry, reconciliation, certificate maintenance, audit retention and health checks. Test clocks generate missed intervals deterministically and claim each task/time key once, preventing overlapping or duplicate execution within the simulation.

## Cloudflare mapping

A future implementation may map enqueue to Cloudflare Queues, handler execution to a Worker consumer, dead letters to a dedicated queue/store, and schedules to Cron Triggers. The business handler must remain provider-independent. Every job needs a stable idempotency key, bounded attempts, lease/visibility semantics, correlation ID, redacted logging, cancellation policy and an operational owner.

Activation requires queue/Cron approval, bindings, dead-letter retention, worker secrets, concurrency limits, alerting and replay/runbook tests. No Queue, Worker consumer or Cron Trigger was created.

