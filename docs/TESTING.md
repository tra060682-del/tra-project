# Verification

Run `npm test` for ten reference-model tests: opening price, proxy competition, equal maximum priority, reserve below/crossing, no bids, close extension, unchanged early closing, closed-auction rejection and invalid data. SQL RPC is authoritative; reference tests are not SQL integration coverage.

Run `npm run typecheck` and `npm run build`. Before launch add actual Supabase tests for ownership/RLS, role escalation, idempotency, concurrent bidders, simultaneous closing, associated intermediary exclusion, accepted terms and financial immutability. Add Playwright journeys for onboarding/curation/publication/enquiry/auction/fulfilment once connected. Desktop browser QA verified the home layout, query search (four records to one matching artwork), and auction-lobby disclosure. Mobile browser QA and database execution remain pending.

Verified in this environment: production build passed, strict TypeScript check passed, all 10 reference tests passed. Desktop browser inspection confirmed home, catalogue URL search and auction lobby. PostgreSQL migration has not been executed.
