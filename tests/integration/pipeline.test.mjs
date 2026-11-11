import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';

const read = path => readFile(new URL(`../../${path}`, import.meta.url), 'utf8');

test('CI has an aggregate required check and never deploys production', async () => {
  const ci = await read('.github/workflows/ci.yml');
  assert.match(ci, /required-checks:/);
  assert.match(ci, /npm run test:database/);
  assert.match(ci, /npm run test:e2e/);
  assert.match(ci, /npm run build:cloudflare/);
  assert.match(ci, /NEXT_PUBLIC_SUPABASE_URL: https:\/\/ocstvctvmychromkcurw\.supabase\.co/);
  assert.doesNotMatch(ci, /supabase db push|netlify deploy --prod/i);
});

test('Cloudflare configuration is non-interactive and isolates Worker environments', async () => {
  const config = await read('cloudflare.config.ts');
  const packageJson = JSON.parse(await read('package.json'));
  assert.match(config, /mode === "production" \? "tra-project"/);
  assert.match(config, /tra-project-\$\{mode \|\| "development"\}/);
  assert.equal(packageJson.scripts['build:cloudflare'], 'node scripts/cloudflare-build.mjs');
  assert.equal(packageJson.scripts['deploy:cloudflare'], 'node scripts/cloudflare-deploy.mjs');
  assert.doesNotMatch(packageJson.scripts['deploy:cloudflare'], /init|migrate/);
});

test('Cloudflare development guard accepts development and rejects production Supabase', () => {
  const baseEnv = {
    ...process.env,
    CLOUDFLARE_DEPLOY_ENV: 'development',
    SUPABASE_EXPECTED_PROJECT_REF: 'ocstvctvmychromkcurw',
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_synthetic_test_only',
    NEXT_PUBLIC_SITE_URL: 'https://tra-project-development.workers.dev',
  };
  const valid = spawnSync(process.execPath, ['scripts/cloudflare-build.mjs', '--validate-only'], {
    cwd: new URL('../..', import.meta.url),
    env: { ...baseEnv, NEXT_PUBLIC_SUPABASE_URL: 'https://ocstvctvmychromkcurw.supabase.co' },
  });
  assert.equal(valid.status, 0, valid.stderr?.toString());
  const invalid = spawnSync(process.execPath, ['scripts/cloudflare-build.mjs', '--validate-only'], {
    cwd: new URL('../..', import.meta.url),
    env: { ...baseEnv, NEXT_PUBLIC_SUPABASE_URL: 'https://aewoiynwpyqawiluwlkj.supabase.co' },
  });
  assert.notEqual(invalid.status, 0);
});

test('production migration remains an approval-gated runbook action', async () => {
  const runbook = await read('docs/DEPLOYMENT_RUNBOOK.md');
  assert.match(runbook, /explicit production approval/i);
  assert.match(runbook, /never automated/i);
  assert.match(runbook, /verified backup/i);
});

test('environment guidance isolates development from production', async () => {
  const config = await read('docs/ENVIRONMENT_CONFIGURATION.md');
  assert.match(config, /tra-development/);
  assert.match(config, /must not equal/i);
  assert.match(config, /service.role/i);
});

test('privileged development workflow cannot run for pull requests', async () => {
  const workflow = await read('.github/workflows/development-integration.yml');
  assert.match(workflow,/environment: development/);
  assert.doesNotMatch(workflow,/pull_request(?:_target)?:/);
  assert.match(workflow,/DEV_SUPABASE_SERVICE_ROLE_KEY/);
});

test('Netlify preview guard accepts development and rejects production Supabase', () => {
  const baseEnv = {
    ...process.env,
    CONTEXT:'deploy-preview',
    SUPABASE_EXPECTED_PROJECT_REF:'ocstvctvmychromkcurw',
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:'sb_publishable_synthetic_test_only',
    DEPLOY_PRIME_URL:'https://deploy-preview-1--therealart.netlify.app',
  };
  const valid = spawnSync(process.execPath,['scripts/netlify-build.mjs','--validate-only'],{
    cwd:new URL('../..',import.meta.url),env:{...baseEnv,NEXT_PUBLIC_SUPABASE_URL:'https://ocstvctvmychromkcurw.supabase.co'}
  });
  assert.equal(valid.status,0,valid.stderr?.toString());
  const invalid = spawnSync(process.execPath,['scripts/netlify-build.mjs','--validate-only'],{
    cwd:new URL('../..',import.meta.url),env:{...baseEnv,NEXT_PUBLIC_SUPABASE_URL:'https://aewoiynwpyqawiluwlkj.supabase.co'}
  });
  assert.notEqual(invalid.status,0);
});
