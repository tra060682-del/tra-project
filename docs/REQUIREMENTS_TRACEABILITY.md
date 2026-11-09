# Traceability — foundation release

| Requirement | Current state | Next acceptance step |
|---|---|---|
| Premium public gallery | Implemented with labelled sample catalogue | Authorised Cloudinary images and database queries |
| URL filters and artwork details | Implemented | Expand configurable taxonomy and dimensions |
| Five roles | SQL model, server gates, permission design | Super-admin role tooling and separate role workspaces |
| Optional intermediary association | Dated SQL model and bid conflict checks | Mutual authorisation, scoped delegation and history UI |
| Auction lobby | Informational preview implemented | Live database lots, watchlist/bid controls, schedule filters |
| Proxy bidding and reserves | SQL RPC and reference tests implemented | Actual Supabase integration, concurrency and RLS tests |
| Closing extension and winner | SQL/reference logic implemented | Scheduler, failure recovery and notification delivery |
| Buyer auction accounts | Design and verified-email gate implemented | Auth/terms screens, session refresh, eligibility controls |
| Curator review | Permission design only | Review queues and audited recommendations |
| Artist onboarding and declaration | Pending | Forms, immutable acceptance and review service |
| Assisted sale | Auction sale record only | Enquiry conversion and reviewed commercial snapshots |
| Manual payment links | Pending | Secure tracking and evidence-based payment confirmation |
| Artist-issued certificate | Copy/architecture only | Private files, version history, sharing controls |
| Artist dispatch and settlements | Pending | Restricted views, validated transitions and calculations |
| Master data and legal CMS | Pending | Database-backed management and current-version enforcement |
| Audit and RLS | Auction foundation implemented | Domain coverage and database isolation tests |
| Netlify and GitHub | Netlify config; no remote/deployment | Connect chosen accounts and run deployment checks |
| Tests | 10 reference-model tests | SQL parity/security/concurrency, integration and E2E |

Do not present pending rows as completed features.
