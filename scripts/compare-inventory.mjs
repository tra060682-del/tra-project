import {readFile, mkdir, writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';

const approved = 'docs/database-inventory/tra_production_full_inventory.csv.csv';
const current = 'docs/database-inventory/tra_production_predeployment.csv';
const normalize = value => value.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').trim();
const digest = value => createHash('sha256').update(value).digest('hex');

const [leftRaw, rightRaw] = await Promise.all([readFile(approved, 'utf8'), readFile(current, 'utf8')]);
const left = normalize(leftRaw);
const right = normalize(rightRaw);
const expected = ['primary_key_constraint','unique_constraint','foreign_key_constraint','check_constraint','index','rls_table','rls_policy','trigger','function','enum','table_grant','column_grant','function_grant','object_catalog','data_quality','export_manifest'];
const missing = expected.filter(section => !right.includes(`\"${section}\"`) && !right.includes(`\n${section},`) && !right.includes(`\n\"${section}\",`));
const equal = left === right;
await mkdir('artifacts', {recursive: true});
await writeFile('artifacts/schema-drift-report.md', `# Schema drift report\n\n- Approved SHA-256: \`${digest(left)}\`\n- Current SHA-256: \`${digest(right)}\`\n- Required sections: ${missing.length ? `missing ${missing.join(', ')}` : 'all present'}\n- Semantic comparison: **${equal ? 'PASS' : 'FAIL'}**\n`);
if (missing.length || !equal) {
  console.error(`Schema drift check failed. Missing sections: ${missing.join(', ') || 'none'}; inventories equal: ${equal}.`);
  process.exit(1);
}
console.log('Schema drift check PASS: approved and predeployment inventories are identical and complete.');
