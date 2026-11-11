import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { validateCloudflareEnvironment } from './cloudflare-environment.mjs';

const { deploymentEnvironment } = validateCloudflareEnvironment();
console.log(`Cloudflare ${deploymentEnvironment} environment validation PASS.`);

if (process.argv.includes('--validate-only')) process.exit(0);

const viteCli = fileURLToPath(new URL('../node_modules/vite/bin/vite.js', import.meta.url));
const result = spawnSync(process.execPath, [viteCli, 'build', '--mode', deploymentEnvironment], {
  stdio: 'inherit',
  env: process.env,
});
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);
mkdirSync(new URL('../.cloudflare/', import.meta.url), { recursive: true });
writeFileSync(new URL('../.cloudflare/tra-build-environment', import.meta.url), `${deploymentEnvironment}\n`);
