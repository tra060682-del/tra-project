# Environment configuration

Credentials belong in platform secret stores, never source control. Public Supabase publishable keys are safe to expose only when RLS is correctly enforced; service-role keys remain server/CI-only.

## Environment matrix

| Context | Supabase project | Database access | Purpose |
|---|---|---|---|
| Local/required PR CI | disposable local stack | localhost only | migration, RLS, Auth, unit/E2E tests |
| GitHub `development` environment | `tra-development` | development only | scheduled synthetic integration |
| Netlify Deploy Preview | `tra-development` | browser publishable key only | preview UI/auth; never production data |
| Netlify production | existing tRA production project | browser publishable key only | approved production application |
| Cloudflare development Worker | `tra-development` | browser publishable key only | Workers preview and route validation |
| Cloudflare production Worker | existing tRA production project | browser publishable key only | separately approved Workers release |

`DEV_SUPABASE_PROJECT_REF` must not equal `PROD_SUPABASE_PROJECT_REF`. The development smoke script also requires the development URL hostname to match the development project ref and refuses a mismatch.

## GitHub development secrets

Configure these on the protected `development` environment:

| Secret | Value/use |
|---|---|
| `DEV_SUPABASE_URL` | `https://<tra-development-ref>.supabase.co` |
| `DEV_SUPABASE_PUBLISHABLE_KEY` | development publishable/anon key |
| `DEV_SUPABASE_SERVICE_ROLE_KEY` | development-only cleanup/provisioning; never exposed to the app |
| `DEV_SUPABASE_PROJECT_REF` | development project ref |
| `PROD_SUPABASE_PROJECT_REF` | production ref used only as a non-secret inequality guard |
| `SUPABASE_ACCESS_TOKEN` | scoped token with read access to `tra-development`, used only for the 13 read-only verification queries |

Do not add a production database password. Scope `SUPABASE_ACCESS_TOKEN` to the minimum development-project permissions and never print CLI environment or key output.

## Netlify variables

Set these separately by Deploy Preview and Production context in the existing site UI:

| Variable | Deploy Preview | Production |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | development URL | production URL |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | development publishable key | production publishable key |
| `NEXT_PUBLIC_SITE_URL` | set automatically from Netlify `DEPLOY_PRIME_URL` | `https://therealart.in` |
| `CLOUDINARY_CLOUD_NAME` | development cloud/name when uploads are enabled | production cloud/name |
| `CLOUDINARY_API_KEY` | development key when required server-side | production key |
| `CLOUDINARY_API_SECRET` | secret, server-only | secret, server-only |

Never create `NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY`. Never put a service-role key or Cloudinary secret in a `NEXT_PUBLIC_*` variable.

## Cloudflare Workers variables

Configure development and production as separate Cloudflare build/deployment environments. Development must use Worker `tra-project-development`, `CLOUDFLARE_DEPLOY_ENV=development`, `SUPABASE_EXPECTED_PROJECT_REF=ocstvctvmychromkcurw`, the development Supabase URL/publishable key, and its own HTTPS `NEXT_PUBLIC_SITE_URL`. Production uses Worker `tra-project`, `CLOUDFLARE_DEPLOY_ENV=production`, the production ref/URL/publishable key, and `NEXT_PUBLIC_SITE_URL=https://therealart.in`.

Deployment automation also needs `CLOUDFLARE_ACCOUNT_ID` and a scoped `CLOUDFLARE_API_TOKEN` in the platform secret store. Never expose either in logs or commit them. Set `CLOUDFLARE_PRODUCTION_APPROVED=true` only for the explicitly approved production run. Service-role keys are prohibited in Workers.

`netlify.toml` commits only non-secret expected project references. Set the two Supabase browser variables explicitly in both the **Deploy Previews** and **Branch deploys** contexts; do not inherit them from Production. The build must fail if a preview resolves to the production project. Keep all service-role, database-password, and Supabase access tokens out of Netlify.

## Supabase Auth URLs

For `tra-development`, configure a non-production site URL and allow exact callbacks for local and preview testing:

- `http://localhost:3000/auth/callback`
- `http://127.0.0.1:3000/auth/callback`
- the exact Netlify Deploy Preview callback URL(s)
- the exact development Workers callback URL, for example `https://tra-project-development.<account-subdomain>.workers.dev/auth/callback`

Use a Netlify wildcard only after confirming the existing site slug and reviewing Supabase's redirect wildcard rules. For production, the site URL is `https://therealart.in` and the callback/recovery allow-list must include `https://therealart.in/auth/callback` and `https://therealart.in/reset-password`. Authentication settings are changed manually under approval, not by these workflows.

## Local configuration

Copy `.env.example` to `.env.local` and use only development values. `supabase/config.toml` requires email confirmation. The development project history marks the incompatible foundation applied without execution, then applies the production-compatible baseline and artist migration. The disposable rehearsal runner still constructs its production-like baseline explicitly and never contacts production.
