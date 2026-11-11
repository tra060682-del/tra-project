# Cloudflare Workers deployment

## Adapter decision

This project uses vinext with Cloudflare's Vite plugin and typed `cloudflare.config.ts`. The installed compatibility scanner reports 100% support for the application's Next.js imports and structure, including App Router pages, route handlers, `src/proxy.ts`, middleware behavior, and Server Actions. OpenNext configuration must not be mixed into this deployment.

The checked-in setup was generated non-interactively with:

```text
npx vinext init --platform=cloudflare --name=tra-project --cdn-cache=none --data-cache=none --image-optimization=none
```

No initializer or migration command is part of build or deploy. The Worker uses compatibility date `2026-11-11`. Use Node `22.23.0` or a version satisfying the repository `engines.node` range; older 22.x and Node 24 before 24.22 do not satisfy the installed `cf` CLI.

## Commands

Install and validate:

```text
npm ci
npm run typecheck:cloudflare
npm run check:cloudflare
```

Exact Cloudflare build command:

```text
npm run build:cloudflare
```

Exact Cloudflare deploy command:

```text
npm run deploy:cloudflare
```

The deployment wrapper reuses the already validated build with `--skip-build`, verifies that its recorded environment matches the requested deployment, sets CI/non-interactive behavior, and never runs setup prompts. Development is deployed with vinext's `--env development` mode to Worker `tra-development`. Production resolves to Worker `tra-project` and is blocked unless `CLOUDFLARE_PRODUCTION_APPROVED=true` is present after approval.

## Required environment values

| Variable | Development | Production |
|---|---|---|
| `CLOUDFLARE_DEPLOY_ENV` | `development` | `production` |
| `SUPABASE_EXPECTED_PROJECT_REF` | `ocstvctvmychromkcurw` | approved production ref |
| `NEXT_PUBLIC_SUPABASE_URL` | tra-development URL | production URL |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | development publishable key | production publishable key |
| `NEXT_PUBLIC_SITE_URL` | `https://tra-development.tra060682.workers.dev` | `https://therealart.in` |
| `CLOUDFLARE_ACCOUNT_ID` | secret-store value | secret-store value |
| `CLOUDFLARE_API_TOKEN` | scoped Worker deployment token | scoped Worker deployment token |
| `CLOUDFLARE_PRODUCTION_APPROVED` | unset | `true` for the approved run only |

`NEXT_PUBLIC_*` values are build inputs and must be configured in the Cloudflare build environment as well as any runtime settings. Never provide a Supabase service-role key to a Worker. Cloudinary server credentials remain separate per environment when upload routes are enabled.

## Cloudflare dashboard

Use the existing Cloudflare account and the repository root. Development targets the dedicated `tra-development` Worker; production remains `tra-project`. Configure Node `22.23.0` or newer within the supported engine range, `npm ci` as dependency installation, `npm run build:cloudflare` as build, and `npm run deploy:cloudflare` as deploy. Store account ID, API token, Supabase publishable key, and any Cloudinary credentials as protected variables. Feature/development builds must select the development values above; do not inherit production Supabase variables.

Before enabling a production custom domain, add the exact Worker callback and recovery URLs to the matching Supabase Auth redirect allow-list and smoke-test the generated `workers.dev` URL. Changing `therealart.in` DNS or removing Netlify is outside this configuration.

## Local Worker verification

After a successful build, run `npm run preview:cloudflare`, then verify `/`, `/artworks`, `/join-as-artist`, `/login`, and `/auth/callback`. A callback request without a Supabase code must redirect to the login error path. Registration and login forms must include Server Action bindings. Full account creation requires the configured tra-development project and a synthetic test user.
