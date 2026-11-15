# Dashboard development preview

The dashboard preview is an isolated, development-only visual review surface. It uses the existing tRA dashboard design system and hard-coded synthetic fixtures. It does not authenticate as a real user, query Supabase, call application APIs, or provide server actions.

## Local URLs

- `http://localhost:3000/dev/dashboard-preview/super-admin`
- `http://localhost:3000/dev/dashboard-preview/admin`
- `http://localhost:3000/dev/dashboard-preview/artist`
- `http://localhost:3000/dev/dashboard-preview/intermediary`
- `http://localhost:3000/dev/dashboard-preview/collector`
- Index: `http://localhost:3000/dev/dashboard-preview`

Every screen displays `DEVELOPMENT DEMO`. All controls that would write data, change permissions, upload files, approve records, send invitations, contact providers, take payment, or affect an auction are disabled.

## Security boundary

- The route layout invokes `requireDevelopmentDashboardPreview()` before rendering.
- That guard accepts only `NODE_ENV=development`; production and test runtimes receive Next.js `notFound()`.
- There is no public environment-variable override and no preview API route.
- Fixtures import `server-only` and contain synthetic `DEMO-*` references.
- Preview pages import neither Supabase nor real dashboard authorization/data modules.
- Existing `/admin`, `/artist`, `/intermediary`, `/workspace`, and `/account` authorization remains unchanged.
- Metadata is `noindex`, `nofollow`, and `nocache`.

## Verification

Run:

```text
npm run test:dashboard-preview
npm run test:e2e -- --grep "development dashboard|preview navigation|preview layout"
```

The production-boundary check is completed by building with `npm run build`, starting the production server, and confirming the preview URL returns HTTP 404.
