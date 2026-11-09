# Netlify deployment preparation

Source includes `netlify.toml` for a standard Next.js build. After local verification, create/connect the intended GitHub repository, link it in Netlify and use the current supported Netlify Next.js runtime. Run `npm ci`, `npm test`, `npm run typecheck`, `npm run build` before deployment. Set `NEXT_PUBLIC_SITE_URL` to the exact production origin so bid-origin validation works. Configure Supabase redirect URLs accordingly.

This task has not created a GitHub remote, provisioned Supabase or deployed to Netlify. Netlify runtime compatibility must be checked against the installed Next.js lockfile before production. Preview is deliberately noindex. Set production sitemap, canonical metadata and indexing policy when approved content is ready.
