import {execFileSync} from 'node:child_process';
import {mkdir, readFile, writeFile} from 'node:fs/promises';

const npx = process.platform === 'win32' ? 'npx.cmd' : 'npx';
const container = 'supabase_db_tra-project';
const run = (command, args, options={}) => execFileSync(command, args, {encoding:'utf8', stdio:['ignore','pipe','pipe'], ...options});
const sql = async (path,{tuplesOnly=false}={}) => {
  const body = await readFile(path);
  const outputArgs = tuplesOnly ? ['-A','-t','-F','|'] : [];
  return run('docker', ['exec','-i',container,'psql','-X','-v','ON_ERROR_STOP=1',...outputArgs,'-U','postgres','-d','postgres'], {input:body,stdio:['pipe','pipe','pipe']});
};
const windowsCommand = args => ['npx.cmd','--yes','supabase@latest',...args].join(' ');
const cli = args => process.platform === 'win32'
  ? run(process.env.ComSpec || 'cmd.exe',['/d','/s','/c',windowsCommand(args)])
  : run(npx,['--yes','supabase@latest',...args]);
const files = {
  baseline:'supabase/tests/artist_auth_production_baseline.sql',
  migration:'supabase/migrations/202611090001_artist_auth.sql',
  verify:'supabase/verify_artist_auth_migration.sql',
  security:'supabase/tests/artist_auth_security_tests.sql',
  rollback:'supabase/rollback/202611090001_artist_auth.rollback.sql',
  rollbackVerify:'supabase/tests/artist_auth_rollback_verify.sql',
  cleanup:'supabase/tests/artist_auth_rehearsal_cleanup.sql',
};
let started = false;
const configPath = 'supabase/config.toml';
const originalConfig = await readFile(configPath,'utf8');
const rehearsalConfig = originalConfig.replace(
  /(\[db\.migrations\][\s\S]*?\benabled\s*=\s*)true/,
  '$1false',
);
if (rehearsalConfig === originalConfig) throw new Error('Could not disable automatic migrations for isolated rehearsal');
const results = [];
try {
  await writeFile(configPath,rehearsalConfig);
  try {
    cli(['start','-x','realtime,storage-api,imgproxy,postgres-meta,studio,edge-runtime,logflare,vector,supavisor']);
  } finally {
    await writeFile(configPath,originalConfig);
  }
  started = true;
  await sql(files.baseline); results.push('Production-like baseline: PASS');
  await sql(files.migration); results.push('Forward migration transaction: PASS');
  const verification = await sql(files.verify,{tuplesOnly:true});
  const issueRows = [...verification.matchAll(/^([a-z_]+)\|(\d+)\r?$/gm)].filter(([,name]) => name !== 'check_name');
  const nonZero = issueRows.filter(([, , count]) => Number(count) !== 0);
  if (!issueRows.length || nonZero.length) throw new Error(`Verification issue counts invalid: ${nonZero.map(match=>match[0].trim()).join(', ') || 'no issue rows detected'}`);
  results.push(`Verification issue counts (${issueRows.length}): PASS`);
  await sql(files.security); results.push('RLS and privilege-escalation tests: PASS');
  run(process.execPath, ['scripts/local-auth-rehearsal.mjs'], {
    env:{...process.env,NODE_TLS_REJECT_UNAUTHORIZED:'0'},
  }); results.push('Auth HTTP/email verification: PASS');
  await sql(files.rollback); results.push('Rollback transaction: PASS');
  await sql(files.rollbackVerify); results.push('Rollback preservation verification: PASS');
  await sql(files.cleanup); results.push('Synthetic-data cleanup: PASS');
  await mkdir('artifacts',{recursive:true});
  await writeFile('artifacts/migration-readiness.md', `# Disposable database rehearsal\n\nGenerated: ${new Date().toISOString()}\n\n${results.map(item=>`- ${item}`).join('\n')}\n\nNo production connection was used.\n`);
  console.log(results.join('\n'));
} catch (error) {
  const safe = `${error.stderr || error.message || error}`.replace(/(?:eyJ|sb_)[A-Za-z0-9._-]+/g, '[REDACTED]');
  console.error(safe.slice(-6000));
  process.exitCode = 1;
} finally {
  await writeFile(configPath,originalConfig);
  if (started) {
    try { cli(['stop','--no-backup']); } catch { console.error('Local Supabase cleanup failed; run npx supabase stop --no-backup.'); }
  }
}
