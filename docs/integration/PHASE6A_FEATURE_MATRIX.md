# Phase 6A feature matrix

Status reflects the current unapplied migration and disabled server flags. “Functional with Limitations” means a real existing baseline read is present; “Preview Only” means UI/contracts exist with no write claim; “Blocked” means an approval, migration or provider is required.

| Feature | Dashboard | Source endpoint | Target | Database / permission | Status | Tests | Approval / next action |
|---|---|---|---|---|---|---|---|
| Wishlist | Collector | #49-50 | Collector RSC + toggle action | proposed wishlist; own user | Preview Only | unit, integration, browser, DB | approve migration/flag |
| Recently viewed | Collector | discovery model | record/clear actions | proposed recent; own user | Preview Only | integration, DB | approve privacy/flag |
| Shopping bag | Collector | #44-46 | bag action/RSC | proposed bag; own user | Preview Only | integration, browser, DB | approve migration/flag |
| Checkout | Collector | #47 | totals contract | sale transaction | Blocked | unit totals | tax/order/payment approval |
| Submit/view offer | Collector | #53-54 | offer action/RSC | proposed offer; active buyer | Preview Only | unit, integration, DB | approve rules/migration |
| Counter/accept/reject/withdraw | Collector, Artist, Admin | #41, #48, #55, #59 | transition action | locked RPC; scoped actor | Preview Only | unit, integration, DB | actor-policy approval |
| Reservations | Collector, Artist | COM contract | reservation action/RSC | locked RPC; own/seller scope | Preview Only | unit, integration, DB | duration/cancellation approval |
| Order history/details | Collector, Artist, Intermediary, Admin | #42-43, #56, #214 | scoped baseline RSC | existing sales; ownership/RBAC | Functional with Limitations | integration, browser | approve write lifecycle |
| Order creation | Collector/Admin | #47 | typed contract only | proposed sale snapshot | Blocked | unit totals, DB offer path | checkout approval |
| Payment intent/attempt | Collector, Finance | #144-149 | provider-neutral schema | proposed payment; payments.manage | Blocked | integration, DB | provider + Phase 6B |
| Payment confirmation/webhook | Finance | #148-149 | no active route | signed provider callback | Blocked | design/static, DB idempotency | provider/security approval |
| Refund request | Admin, Finance | #43 | gated action | proposed refund; payments.manage | Preview Only | integration, DB | policy/migration/provider |
| Immutable ledger | Finance, Super Admin | payment contract | posting RPC/reconciliation UI | proposed ledger; service-only write | Preview Only | unit, DB | finance/migration approval |
| Artist settlement | Artist, Finance | #43, #214 | baseline RSC + proposal | existing settlement + event | Functional with Limitations | integration, DB | transfer provider/policy |
| Intermediary commission | Intermediary, Finance | intermediary contract | scoped preview | proposed commission; representation | Preview Only | integration, DB | entitlement rule approval |
| Shipping/fulfilment | Artist, Collector, Admin | #57-58 | baseline shipment RSC | existing shipment; owner/RBAC | Functional with Limitations | unit, integration, browser | approve transition/privacy |
| Courier integration | Operations | n/a | status only | external provider | Blocked | feature-gate test | Phase 6B provider |
| Certificate management | Artist, Admin | #185-187 | scoped preview | existing certificate + proposal | Functional with Limitations | integration, DB | issuer/legal/migration |
| Public verification | Public | #39/#198 | gated verifier contract | proposed token/hash RPC | Blocked | unit token, integration, DB | rate limit/security approval |
| In-app notifications | All | #51-52 | RSC + mark-read action | proposed notifications; own user | Preview Only | unit, integration, DB | migration/flag |
| Email notifications | All | #51-52 | contracts only | proposed delivery + provider | Blocked | dedupe design | provider/templates/consent |
| Private media | Artist/Admin/Operations | cert-doc #33-36 | storage contract/status | proposed private asset/audit | Blocked | integration, DB | storage/scanner approval |
| Operational exceptions | Admin, Super Admin | #8/#193 | Admin commerce projection | proposed exception; reports.view | Preview Only | integration, browser, DB | runbook/migration |
| Reconciliation | Finance, Super Admin | #67/#144 | Admin commerce projection | ledger/payment/settlement | Preview Only | unit, DB | accounting policy |
| Auction operational readiness | Admin, Super Admin | auction admin endpoints | existing preview + launch gate | existing auction controls; admin | Functional with Limitations | integration, browser, DB | launch procedure approval |
| Live bidding/payment/settlement | Collector/Finance | auction/payment endpoints | explicitly disabled | concurrency + provider required | Blocked | browser disabled, DB finance denial | Phase 6B+ explicit launch |

No row is labelled Fully Functional because each new Phase 6A operational feature either depends on the unapplied proposal or is a limited read over the existing baseline.

