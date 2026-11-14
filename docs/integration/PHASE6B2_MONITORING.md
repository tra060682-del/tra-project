# Phase 6B.2 monitoring and operations

The existing structured logger and alert manager remain the operational baseline. Records include timestamp, service, operation, correlation/request identifiers, category, outcome, duration and safe error classification. Recursive redaction covers credentials, tokens, authorization headers, payment data, private documents and personal contact data.

The Super Admin Integration Operations page now reports provider, mode, configuration, approval, operational state, last successful test, last failure and outstanding boundary. It distinguishes not configured, configured but disabled, local simulation ready, sandbox connected, sandbox verified and production approved. Configuration presence alone never produces `sandbox_verified`.

No external sink or alert recipient is configured. A later approval must select a processor and region, define sampling/retention, prohibit payload/PII ingestion, set alert thresholds and on-call ownership, and test redaction before any development telemetry leaves the Worker.
