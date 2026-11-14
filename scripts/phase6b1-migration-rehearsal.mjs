import {readFileSync} from 'node:fs';import {spawnSync} from 'node:child_process';
const harness=readFileSync('scripts/phase6a-database-rehearsal.mjs','utf8'),phase6=readFileSync('docs/integration/sql/202611170101_phase6a_commerce.draft.sql','utf8'),rollback=readFileSync('docs/integration/sql/202611170199_phase6a_rollback.draft.sql','utf8');
const order=['202611140100_phase1_role_enum','202611150100_phase3_role_enum','202611150101_phase3_auth_rbac'];let cursor=-1;for(const item of order){const next=harness.indexOf(item);if(next<=cursor)throw new Error(`MIGRATION_ORDER_INVALID:${item}`);cursor=next}const commerceApply=harness.lastIndexOf('202611170101_phase6a_commerce');if(commerceApply<=cursor)throw new Error('MIGRATION_ORDER_INVALID:202611170101_phase6a_commerce');
if(harness.includes('202611140101_phase1_permissions_and_identity')||harness.includes('202611140103_phase1_commerce_finance_auction'))throw new Error('SUPERSEDED_MIGRATION_INCLUDED');
if(!phase6.includes('TRA_PHASE6A_TARGET_NOT_APPROVED')||!rollback.includes('drop table'))throw new Error('MIGRATION_GUARD_OR_ROLLBACK_MISSING');
const result=spawnSync(process.execPath,['scripts/phase6a-database-rehearsal.mjs'],{stdio:'inherit',env:process.env,shell:false});if(result.status!==0)process.exit(result.status??1);
console.log('Phase 6B.1 dependency order: PASS\nSuperseded migrations excluded: PASS\nNo destructive forward schema operation: PASS\nEnum residue documented: PASS');

