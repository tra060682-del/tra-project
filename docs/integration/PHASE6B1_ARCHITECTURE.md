# Phase 6B.1 integration architecture

## Outcome

Phase 6B.1 introduces local, provider-independent integration seams without external traffic. The design has two executable modes only: `disabled` and `local`. Missing configuration defaults to disabled. Local execution additionally requires a server-side feature decision and the exact `phase6b1-local-only` approval marker. No production/provider mode exists in this phase.

## Modules

| Module | Implementation | Boundary |
|---|---|---|
| Common integration controls | `src/lib/integrations/core.ts` | modes, structured errors, retry classes, timeouts, exact minor units, explicit local approval |
| Payment/refund | `payment.ts` | in-memory intents/refunds, HMAC verification, replay/idempotency and state ordering |
| Email | `email.ts` | 16 branded HTML/text templates and local capture adapter |
| Notifications | `notifications.ts` | preference resolution, mandatory security channel preservation and deduplication |
| Private media | `storage.ts` | validated in-memory private objects, quarantine, owner-only signed access and audit |
| Malware | `malware.ts` | clean/infected/failed/timeout simulation; fail-closed access decision |
| Jobs/schedules | `jobs.ts` | deterministic queue, retries, backoff, dead-letter, deduplication and missed-run claims |
| Observability/alerts | `observability.ts` | structured local logs, recursive redaction, health and suppressed/deduplicated alerts |
| Certificates | `certificate.ts` | 256-bit tokens, SHA-256 lookup, public filtering, audit and local rate limiting |
| Auction load | `auction-load.ts` | serialized synthetic bids and finance/suspension/eligibility checks |
| Reconciliation | `reconciliation.ts` | order/payment/refund/ledger/settlement/commission comparison |
| Diagnostics | `readiness.ts`, `/admin/integrations` | server-only presence/approval checks; read-only Super Admin route |

Provider-specific code must implement the interfaces without entering business components. Provider callbacks will eventually validate transport evidence before invoking transactional database RPCs; no callback route was created.

## Execution rules

1. Authenticate and authorize before entering any integration boundary.
2. Validate ownership/scope, exact amount, currency and immutable business reference.
3. Require the relevant server flag and a recorded activation approval.
4. Apply a timeout and classify errors as never/immediate/transient/rate-limited.
5. Use a stable idempotency key for every side effect.
6. Record a redacted audit/trace event with correlation and request identifiers.
7. Persist state through approved transactional RPCs only after migrations are applied.
8. Never infer success from a redirect, UI state, configuration presence or local simulation.

## Deliberately absent

There is no provider SDK, network client, public webhook, Cloudflare Queue/Cron binding, external monitoring sink, real bucket, scanner, email delivery, payment/refund object, public certificate RPC, live bid, or remote data write. Local adapters always mark results `simulated: true`.

