import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const read=(path)=>readFile(new URL(`../${path}`,import.meta.url),'utf8');

test('public header uses The Reverence of Art and has no auction navigation',async()=>{
  const header=await read('src/components/header.tsx');
  assert.match(header,/THE REVERENCE OF ART/);
  assert.match(header,/Join as Artist/);
  assert.doesNotMatch(header,/\/auctions|Auction lobby/i);
});

test('artist provisioning requires verification and cannot accept a role',async()=>{
  const migration=await read('supabase/migrations/202611090001_artist_auth.sql');
  assert.match(migration,/email_confirmed_at/);
  assert.match(migration,/VERIFIED_EMAIL_REQUIRED/);
  assert.match(migration,/values\(current_user_id,'artist'\)/);
  assert.doesNotMatch(migration,/p_role/);
  assert.match(migration,/revoke all .* from public,anon/i);
});

test('incremental migration preserves production identity and legal tables',async()=>{
  const migration=await read('supabase/migrations/202611090001_artist_auth.sql');
  assert.match(migration,/TRA_SCHEMA_PREFLIGHT_FAILED/);
  assert.equal((migration.match(/create or replace function/gi)??[]).length,1);
  assert.match(migration,/create or replace function public\.register_current_user_as_artist/);
  assert.match(migration,/i\.indnkeyatts=1 and i\.indkey\[0\]=/);
  assert.doesNotMatch(migration,/i\.indkey::smallint\[\]\s*=\s*array/i);
  assert.equal((migration.match(/array_agg\(a\.attname::text order by u\.ord\)/g)??[]).length,3);
  assert.doesNotMatch(migration,/create table (?:if not exists )?public\.(?:profiles|user_roles|legal_documents|legal_document_versions|legal_acceptances)\b/i);
  assert.doesNotMatch(migration,/\b(?:drop|truncate|delete from)\b/i);
  assert.match(migration,/add column if not exists acceptance_statement/);
  assert.match(migration,/artist_onboarding_requests\(artist_id\)/);
  assert.match(migration,/select id into artist_profile_id from public\.artist_profiles where user_id=auth\.uid\(\)/);
  for(const policy of ['artist_admin_all','artist_public_read','artist_self_insert','artist_self_update']){
    assert.match(migration,new RegExp(`\\('artist_profiles','${policy}'\\)`));
  }
  assert.match(migration,/legal_acceptances\(user_id,version_id,accepted_text_snapshot/);
  assert.match(migration,/tra_legal_acceptance_immutable_snapshot/);
  assert.doesNotMatch(migration,/artist_onboarding_legal_requirements|legal_document_version_id|\('artist_onboarding_requests','profile_data'\)/);
  assert.match(migration,/MANDATORY_LEGAL_ACCEPTANCE_REQUIRED/);
});

test('production follow-up and verification scripts are read only',async()=>{
  const followup=await read('supabase/production_schema_followup.sql');
  const singleExport=await read('supabase/production_schema_followup_export.sql');
  const completeExport=await read('supabase/production_schema_complete_export.sql');
  const exportValidation=await read('supabase/validate_production_schema_complete_export.sql');
  const rolloutPreflight=await read('supabase/production_rollout_preflight.sql');
  const verification=await read('supabase/verify_artist_auth_migration.sql');
  for(const sql of [followup,singleExport,completeExport,exportValidation,rolloutPreflight,verification])assert.doesNotMatch(sql,/\b(?:insert|update|delete|alter|create|drop|truncate|grant|revoke)\b/i);
  assert.match(followup,/pg_constraint/);
  assert.match(singleExport,/with inventory/);
  assert.match(completeExport,/select section,object_schema,object_name,details::text as details/);
  for(const section of ['primary_key_constraint','unique_constraint','foreign_key_constraint','check_constraint','index','rls_table','rls_policy','trigger','function','enum','table_grant','column_grant','function_grant','object_catalog','data_quality','export_manifest'])assert.match(completeExport,new RegExp(`'${section}'`));
  assert.doesNotMatch(completeExport,/aclexplode\s*\(\s*coalesce/i);
  assert.doesNotMatch(completeExport,/coalesce\s*\(\s*a\.attacl\s*,\s*'\{\}'::aclitem\[\]/i);
  assert.match(completeExport,/unnest\(coalesce\(r\.relacl,acldefault\('r',r\.relowner\)\)\)/i);
  assert.match(completeExport,/unnest\(a\.attacl\)/i);
  assert.equal((completeExport.match(/aclexplode\(array\[raw_acl\.acl_item\]::aclitem\[\]\)/gi)??[]).length,3);
  assert.match(followup,/information_schema\.triggers/);
  assert.match(followup,/role_table_grants/);
  assert.match(verification,/missing_rpc/);
  assert.match(verification,/duplicate_artist_profile_user/);
  assert.match(verification,/artist_profile_without_auth_user/);
  assert.match(rolloutPreflight,/server_version_num/);
  assert.match(rolloutPreflight,/supabase_migrations\.schema_migrations/);
});

test('auth callback rejects unsafe destinations',async()=>{
  const callback=await read('src/app/auth/callback/route.ts');
  assert.match(callback,/startsWith\('\/'\)/);
  assert.match(callback,/!candidate\.startsWith\('\/\/'\)/);
  assert.match(callback,/exchangeCodeForSession/);
});
