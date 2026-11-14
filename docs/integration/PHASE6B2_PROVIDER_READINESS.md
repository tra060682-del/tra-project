# Phase 6B.2 provider readiness

| Provider | Adapter | Local tests | Sandbox | Credentials/infrastructure | Approval/blocker |
|---|---|---|---|---|---|
| Razorpay | implemented | passed | not connected | test key ID/secret, webhook secret, approved callback | PAY-01/02/03 and provider approval |
| Stripe | implemented | passed | not connected | test secret, webhook secret, approved callback | PAY-01/02/03; Connect excluded |
| Resend | implemented | passed | not connected | API key, verified sender/domain, allowlist | MSG-01/02 and DNS approval |
| Amazon SES | implemented | passed | not connected | region, scoped IAM identity, verified sender/recipients | MSG-01/02 and AWS/DNS approval |
| Cloudflare R2 | implemented against injected binding | passed | no bucket/binding | private dev bucket, Worker binding, signing secret | MED-01 and schema approval |
| Malware scanner | authenticated HTTP adapter | passed | provider unselected | endpoint/token, quarantine workflow | MED-02/provider decision |
| Cloudflare Queues | producer/consumer prepared | passed | no queues/bindings | development queues, DLQ, Worker bindings | infrastructure/topology approval |
| Cron Triggers | schedule contracts prepared | passed | no triggers | approved schedules and Worker triggers | operations approval |
| Monitoring | local logger/alerts | passed | local only | selected sink, scoped token, DPA/retention | monitoring approval |

No provider is operational. The safest next connections are an allowlisted email sandbox and one payment sandbox because their adapters and failure cases are locally validated; both still require explicit approvals. R2/scanning should be connected together, never R2 ingestion alone. Queues can be exercised with synthetic jobs independently of commerce policy after infrastructure approval.

Outstanding decision IDs remain DB-01/02/04, PAY-01/02/03, REF-01, MSG-01/02, MED-01/02, CERT-01, AUC-01, OPS-01, ID-01/02/03 and PROD-01. Recommendations are not approvals.
