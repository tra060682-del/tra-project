import {spawnSync} from 'node:child_process';

const context = process.env.CONTEXT || 'local';
const expectedRef = process.env.SUPABASE_EXPECTED_PROJECT_REF;
const urlValue = process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || '';

if (['production','deploy-preview','branch-deploy'].includes(context)) {
  if (!expectedRef) throw new Error(`SUPABASE_EXPECTED_PROJECT_REF is required for Netlify ${context}`);
  if (!urlValue) throw new Error(`NEXT_PUBLIC_SUPABASE_URL is required for Netlify ${context}`);
  const url = new URL(urlValue);
  if (url.protocol !== 'https:' || url.hostname !== `${expectedRef}.supabase.co`) {
    throw new Error(`Refusing ${context} build: Supabase project does not match the expected context`);
  }
  let privilegedJwt = false;
  if (key.split('.').length === 3) {
    try {
      const payload = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString('utf8'));
      privilegedJwt = payload.role !== 'anon';
    } catch { privilegedJwt = true; }
  }
  if (!key || key.startsWith('sb_secret_') || privilegedJwt) {
    throw new Error(`Refusing ${context} build: a publishable Supabase key is required`);
  }
}

const environment = {...process.env};
if (['deploy-preview','branch-deploy'].includes(context)) {
  const previewUrl = process.env.DEPLOY_PRIME_URL || process.env.URL;
  if (!previewUrl?.startsWith('https://')) throw new Error('A Netlify preview HTTPS origin is required');
  environment.NEXT_PUBLIC_SITE_URL = previewUrl.replace(/\/$/, '');
}
if (context === 'production') environment.NEXT_PUBLIC_SITE_URL = 'https://therealart.in';

if (process.argv.includes('--validate-only')) {
  console.log(`Netlify ${context} environment validation PASS.`);
  process.exit(0);
}

const command = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const result = spawnSync(command, ['run','ci'], {stdio:'inherit', env:environment});
if (result.error) throw result.error;
process.exit(result.status ?? 1);
