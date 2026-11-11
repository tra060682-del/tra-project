import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { validateCloudflareEnvironment } from './cloudflare-environment.mjs';

const { deploymentEnvironment } = validateCloudflareEnvironment();
if (deploymentEnvironment === 'production' && process.env.CLOUDFLARE_PRODUCTION_APPROVED !== 'true') {
  throw new Error('Production deployment requires CLOUDFLARE_PRODUCTION_APPROVED=true after explicit approval');
}
let builtEnvironment;
try {
  builtEnvironment = readFileSync(new URL('../.cloudflare/tra-build-environment', import.meta.url), 'utf8').trim();
} catch {
  throw new Error('No validated Cloudflare build was found; run npm run build:cloudflare first');
}
if (builtEnvironment !== deploymentEnvironment) {
  throw new Error(`Refusing deploy: ${builtEnvironment} build does not match ${deploymentEnvironment} deployment`);
}

const deployCli = fileURLToPath(new URL('../node_modules/@vinext/cloudflare/dist/cli.js', import.meta.url));
const args = [deployCli, 'deploy', '--skip-build'];
if (deploymentEnvironment !== 'production') args.push('--env', deploymentEnvironment);

const result = spawnSync(process.execPath, args, {
  stdio: 'inherit',
  env: { ...process.env, CI: 'true', CF_QUIET: '1' },
});
if (result.error) throw result.error;
process.exit(result.status ?? 1);
