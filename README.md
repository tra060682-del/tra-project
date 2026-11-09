# tRA — foundation release

A Next.js App Router, TypeScript strict, Tailwind, Supabase foundation prepared for Netlify. This is phase 1, not a launch-ready marketplace. All displayed art is explicitly illustrative; no copied Memeraki catalogue or real artist claims.

## Run

Node 22+ and npm are required.

```sh
npm ci
cp .env.example .env.local
npm run dev
npm test
npm run typecheck
npm run build
```

Without Supabase configuration the public sample catalogue runs, protected routes redirect to setup messaging, and the bid handler refuses requests. Production startup: `npm start`.

## Delivered

- Editorial responsive home, query-filtered sample catalogue, artwork details, auction lobby and explanatory pages.
- Five staff/domain roles and optional dated artist–intermediary associations in a foundation migration.
- Server-side role gate for artist and admin routes; no client-side role impersonation.
- Authenticated bid endpoint with Zod validation and database-authoritative proxy-bid transaction.
- Reserve calculation, tie priority, paise money fields, idempotency, closing extension, conflict-of-interest checks and administrator-triggered closing into an unpaid sale.
- RLS and explicit public views excluding maximum bids, reserve prices, buyer identities and private artist information.
- Ten executable auction reference-model tests.

## Not yet delivered

- Connected login, registration/reset/verification screens and session refresh middleware.
- Live catalogue queries, artist onboarding, intermediary management, curator queues, configurable taxonomy/content and final publication UI.
- Operational payment-link, certificate, shipping and settlement modules; only an auction-sale foundation is present.
- Cloudinary upload signing and image rendering; no Cloudinary credentials are collected by this preview.
- Interactive bid controls/watchlists, bidder terms acceptance UI, auction management, notifications and unattended closing scheduler.
- Database integration/RLS concurrency tests, Playwright journeys, mobile browser QA, lint setup and production security review.
- GitHub repository and Netlify deployment: not connected or published.

Do not activate auctions until database tests, terms, abuse prevention, operational workflows and closing automation are complete. A server bid handler and SQL migration are groundwork, not proof of a production auction service.

See `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/WORKFLOWS.md`, `docs/RLS_AND_SECURITY.md` and `docs/ASSUMPTIONS_AND_DECISIONS.md`.
