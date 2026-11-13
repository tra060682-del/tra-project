import {execFile,execFileSync} from 'node:child_process';
import {promisify} from 'node:util';
import {readFile,writeFile} from 'node:fs/promises';

const exec=promisify(execFile),container='supabase_db_tra-project';
const run=(command,args,options={})=>execFileSync(command,args,{encoding:'utf8',stdio:['ignore','pipe','pipe'],...options});
const sqlBody=body=>run('docker',['exec','-i',container,'psql','-X','-v','ON_ERROR_STOP=1','-U','postgres','-d','postgres'],{input:body,stdio:['pipe','pipe','pipe']});
const sql=async(path,prefix='')=>sqlBody(`${prefix}\n${await readFile(path,'utf8')}`);
const cli=args=>process.platform==='win32'?run(process.env.ComSpec||'cmd.exe',['/d','/s','/c',['npx.cmd','--yes','supabase@latest',...args].join(' ')]):run('npx',['--yes','supabase@latest',...args]);
const configPath='supabase/config.toml',original=await readFile(configPath,'utf8'),isolated=original.replace(/(\[db\.migrations\][\s\S]*?\benabled\s*=\s*)true/,'$1false');
const phase1="select set_config('app.tra_phase1_target','ocstvctvmychromkcurw:approved-development-only',false);";
const phase3="select set_config('app.tra_phase3_target','ocstvctvmychromkcurw:approved-development-only',false);";
const rollback1="select set_config('app.tra_phase1_rollback','ocstvctvmychromkcurw:approved-development-rollback',false);";
const bid=(user,maximum,request)=>exec('docker',['exec',container,'psql','-X','-v','ON_ERROR_STOP=1','-U','postgres','-d','postgres','-c',`begin;set local role authenticated;select set_config('request.jwt.claim.sub','${user}',true);select public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',${maximum},'${request}');commit;`]);
const results=[];let started=false;
try{
  if(isolated===original)throw new Error('Could not disable automatic migrations for isolated rehearsal');
  await writeFile(configPath,isolated);try{cli(['start','-x','realtime,storage-api,imgproxy,postgres-meta,studio,edge-runtime,logflare,vector,supavisor']);}finally{await writeFile(configPath,original)}started=true;
  if(process.env.PHASE35_BASELINE_DUMP){
    sqlBody('alter default privileges for role postgres in schema public revoke all on tables from anon,authenticated,service_role;alter default privileges for role postgres in schema public revoke all on functions from anon,authenticated,service_role;alter default privileges for role postgres in schema public revoke all on sequences from anon,authenticated,service_role;');
    await sql(process.env.PHASE35_BASELINE_DUMP);
  }
  else for(const path of ['supabase/migrations/202611080001_production_compatible_baseline.sql','supabase/migrations/202611090001_artist_auth.sql','supabase/migrations/202611120001_auction_lobby.sql','supabase/migrations/202611120002_auction_hardening.sql','supabase/migrations/202611130001_phase1_roles.sql','supabase/migrations/202611130002_phase1_marketplace.sql'])await sql(path);
  results.push(`Schema-only development foundation restore: PASS (${process.env.PHASE35_BASELINE_DUMP?'remote schema-only snapshot':'checked-in migration reconstruction'})`);
  const snapshot=await sql('supabase/tests/phase35_inventory_snapshot.sql');results.push(`Baseline inventory snapshot: PASS (${snapshot.match(/\n\s*(\d+)\s*\n/)?.[1]??'count captured'} public tables)`);
  let guardFailed=false;try{await sql('docs/integration/sql/202611150101_phase3_auth_rbac.draft.sql')}catch(error){guardFailed=/TRA_PHASE3_TARGET_NOT_APPROVED/.test(`${error.stderr||error.message}`)}if(!guardFailed)throw new Error('Phase 3 target guard did not reject an unapproved session');results.push('Remote-target guard fail-closed: PASS');
  await sql('docs/integration/sql/202611140100_phase1_role_enum.draft.sql',phase1);
  await sql('docs/integration/sql/202611150100_phase3_role_enum.draft.sql',phase3);
  await sql('docs/integration/sql/202611150101_phase3_auth_rbac.draft.sql',phase3);
  await sql('docs/integration/sql/202611140102_phase1_catalogue_content_operations.draft.sql',phase1);
  await sql('docs/integration/sql/202611140103_phase1_commerce_finance_auction.draft.sql',phase1);
  results.push('Coherent additive migration sequence: PASS');
  await sql('docs/integration/sql/202611140100_phase1_role_enum.draft.sql',phase1);await sql('docs/integration/sql/202611150100_phase3_role_enum.draft.sql',phase3);results.push('Enum migration repeatability: PASS');
  const inventory=await sql('supabase/tests/phase35_inventory_verify.sql');results.push('Tables, columns, constraints, policies, grants, functions and triggers preserved: PASS');
  await sql('supabase/tests/phase35_security_rehearsal.sql');results.push('Eight-role RLS/RPC and transactional finance tests: PASS');
  await sql('supabase/tests/auction_security_rehearsal.sql');
  await Promise.all([bid('a0000000-0000-0000-0000-000000000003',50000,'a7000000-0000-0000-0000-000000000011'),bid('a0000000-0000-0000-0000-000000000004',30000,'a7000000-0000-0000-0000-000000000012')]);
  await sql('supabase/tests/phase35_auction_finance_rehearsal.sql');await sql('supabase/tests/auction_post_bid_rehearsal.sql');results.push('Auction concurrency, finance conflict, idempotency, close and audit: PASS');
  await sql('docs/integration/sql/202611140199_phase1_rollback.draft.sql',rollback1);await sql('docs/integration/sql/202611150199_phase3_rollback.draft.sql');
  const rollback=await sql('supabase/tests/phase35_rollback_verify.sql');results.push('Rollback and baseline preservation: PASS');
  console.log(results.join('\n'));
}catch(error){const safe=`${error.stdout||''}\n${error.stderr||error.message||error}`.replace(/(?:eyJ|sb_)[A-Za-z0-9._-]+/g,'[REDACTED]');console.error(safe.slice(-12000));process.exitCode=1}
finally{await writeFile(configPath,original);if(started){try{cli(['stop','--no-backup'])}catch{console.error('Local cleanup failed; run npx supabase stop --no-backup.')}}}
