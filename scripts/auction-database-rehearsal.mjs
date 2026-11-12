import {execFile,execFileSync} from 'node:child_process';
import {promisify} from 'node:util';
import {readFile,writeFile} from 'node:fs/promises';
const exec=promisify(execFile),container='supabase_db_tra-project';
const run=(command,args,options={})=>execFileSync(command,args,{encoding:'utf8',stdio:['ignore','pipe','pipe'],...options});
const sql=async(path,{tuplesOnly=false}={})=>{const body=await readFile(path);return run('docker',['exec','-i',container,'psql','-X','-v','ON_ERROR_STOP=1',...(tuplesOnly?['-A','-t','-F','|']:[]),'-U','postgres','-d','postgres'],{input:body,stdio:['pipe','pipe','pipe']});};
const cli=args=>process.platform==='win32'?run(process.env.ComSpec||'cmd.exe',['/d','/s','/c',['npx.cmd','--yes','supabase@latest',...args].join(' ')]):run('npx',['--yes','supabase@latest',...args]);
const configPath='supabase/config.toml',original=await readFile(configPath,'utf8'),isolated=original.replace(/(\[db\.migrations\][\s\S]*?\benabled\s*=\s*)true/,'$1false');
let started=false;
const bid=(user,maximum,request)=>exec('docker',['exec',container,'psql','-X','-v','ON_ERROR_STOP=1','-U','postgres','-d','postgres','-c',`begin; set local role authenticated; select set_config('request.jwt.claim.sub','${user}',true); select public.place_maximum_bid('a6000000-0000-0000-0000-000000000001',${maximum},'${request}'); commit;`]);
try{
  await writeFile(configPath,isolated);
  try{cli(['start','-x','realtime,storage-api,imgproxy,postgres-meta,studio,edge-runtime,logflare,vector,supavisor']);}finally{await writeFile(configPath,original);}
  started=true;
  await sql('supabase/migrations/202611080001_production_compatible_baseline.sql');
  await sql('supabase/migrations/202611090001_artist_auth.sql');
  await sql('supabase/migrations/202611120001_auction_lobby.sql');
  await sql('supabase/migrations/202611120002_auction_hardening.sql');
  const verify=await sql('supabase/verify_auction_lobby_migration.sql',{tuplesOnly:true});
  const issues=[...verify.matchAll(/^([a-z_]+)\|(\d+)\r?$/gm)].filter(([,name,count])=>name!=='check_name'&&Number(count)!==0);
  if(issues.length)throw new Error(`Auction verification failed: ${issues.map(match=>match[0]).join(', ')}`);
  await sql('supabase/tests/auction_security_rehearsal.sql');
  await Promise.all([bid('a0000000-0000-0000-0000-000000000003',50000,'a7000000-0000-0000-0000-000000000011'),bid('a0000000-0000-0000-0000-000000000004',30000,'a7000000-0000-0000-0000-000000000012')]);
  await sql('supabase/tests/auction_post_bid_rehearsal.sql');
  console.log('Auction migrations: PASS\nVerification counts: PASS\nRLS and kill switch: PASS\nConcurrent bids and idempotency: PASS\nAuction closing and audit log: PASS');
}catch(error){console.error(`${error.stderr||error.message||error}`.slice(-8000));process.exitCode=1;}
finally{await writeFile(configPath,original);if(started){try{cli(['stop','--no-backup']);}catch{console.error('Local cleanup failed; run npx supabase stop --no-backup.');}}}
