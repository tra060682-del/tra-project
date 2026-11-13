# Phase 0 source baseline

Status: complete on 2026-11-14 (Pacific/Auckland). This is a documentation-only baseline; no application, database, Worker, DNS, deployment, or production change was made.

## Repositories and branch

- Existing application: `C:\tra\tra-project`
- Emergent export: `C:\tra\tra-emergent\tra-emergent`
- Git remote: `tra060682-del/tra-project`
- Dedicated branch: `integration/emergent-phase0-phase1`
- Branch point: `9a434d4 fix(auth): surface development signup failures safely`
- Development Supabase project verified by linked ref: `ocstvctvmychromkcurw`

No merge, deployment, database migration, staging import, or production operation is part of Phase 0/1.

## Export integrity

`EXPORT_MANIFEST.md` and `FILES.sha256` were read from the export root. All **388/388** checksum entries resolved and matched SHA-256; missing files: **0**; mismatches: **0**. The manifest's 387-file content count excludes `FILES.sha256` itself.

Export inventory:

| Area | Manifest count | Baseline decision |
|---|---:|---|
| Root | 5 | Retain as export evidence |
| Assets | 50 | Preserve binaries and image manifest; rights review before use |
| Backend | 130 | Behavioural source for TypeScript/RPC port; Python runtime will not be deployed |
| Cloudflare | 10 | Historical proxy architecture; existing Next/Vinext Worker remains target |
| Config | 1 | Cron behaviour input only |
| Docs | 12 | Historical evidence; supersession rules below |
| Frontend | 84 | Approved design/interaction reference; port to Next.js rather than copy Vite shell |
| Memory | 1 | Product intent evidence |
| Supabase | 2 | Staging schema/rollback evidence; never rerun the completed import |
| Tests | 92 | Behavioural acceptance evidence to port to current test lanes |

The export manifest reports that Python compilation, strict frontend TypeScript checking and a secret scan passed before export. Phase 0 did not reinstall Emergent dependencies or reproduce its external services.

## Authority and supersession

Authority order for Phase 1:

1. Executable source and database constraints/RLS/RPCs.
2. Executable tests and browser checks.
3. Current development schema inspected read-only.
4. Generated OpenAPI/documentation only where consistent with 1–3.
5. Historical status and audit reports.

Superseded findings:

| Historical statement | Authoritative finding | Disposition |
|---|---|---|
| 128 Emergent endpoints | 214 business route decorators in `server.py` and `routers/*.py` | 128 was a regex undercount that omitted `admin_router` and `users_router` |
| Exported OpenAPI has 89 operations | Source has 214 business operations | OpenAPI is retained as historical, not used as full contract |
| Implementation status says no committed Playwright suite | 46 browser-check scripts plus 40 metadata files are present | Status statement is obsolete |
| Initial staging report describes 591 records and a failed classification check | Final re-import has 400 verified records and 51/51 checks | Earlier run remains audit history; final section is authoritative |
| Export README calls the project a bare skeleton | Source implements the full audited application | README is template history |

Historical files must not be deleted or rewritten to hide their former state. When cited, they must be labelled with their date and superseded status.

## Read-only development evidence

A Supabase CLI schema dump of `public` and `emergent_staging`, and a data-only dump of `emergent_staging`, were taken read-only for analysis. They are temporary local evidence and are excluded from the commit because the data dump contains record content and personal data.

- Schema snapshot SHA-256: `EDA81A3098B4EB2B113BA0E676DD7CE131D52E465A40742B2117041793268D40`
- Staging-data snapshot SHA-256: `F3C5BCF581C29143E6818B56F6B03103621674488E554F039216D7A26830BFC7`
- Public tables observed: 40
- Public enum types observed: 15
- Staging application collections observed: 15
- Staged application records observed: 400
- Staging support tables: `import_runs`, `id_map`, `attribution_audit`

The snapshots were not loaded, replayed or applied. `emergent_staging` remains private, RLS-enabled and unavailable to `anon`/`authenticated`.

A second read-only schema dump after completing the documents produced the identical SHA-256 `EDA81A3098B4EB2B113BA0E676DD7CE131D52E465A40742B2117041793268D40`, verifying that the inspected development schema did not change during Phase 0/1.

## Existing application baseline

Before documentation work:

- Unit tests: 17/17 passed.
- Integration tests: 15/15 passed.
- Next route type generation passed.
- TypeScript checking passed.
- Working tree was clean.
- Current branch was `feature/tra-artist-onboarding` before the dedicated integration branch was created.

No application tests were changed in Phase 0/1.

## Secret and production safety

- Documentation contains variable names and public project references only, never credential values.
- Temporary dumps are not deliverables and must be removed before commit.
- No production project was queried or changed.
- No `db push`, SQL execution, auth administration, Worker deployment, DNS operation or import script was run.
- Draft SQL is stored under `docs/integration/sql`, not `supabase/migrations`, and includes a development-only approval guard.

## Baseline acceptance

- Export checksum coverage: 388/388.
- Business endpoint source coverage target: 214/214.
- Staging collection coverage target: 15/15.
- Staging record coverage target: 400/400.
- Application functionality changes allowed: none.
- Database changes allowed: none.
