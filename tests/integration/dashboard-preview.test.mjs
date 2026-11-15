import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';

const read=path=>readFile(path,'utf8');

test('dashboard previews are hard-gated to the development runtime',async()=>{
 const [guard,layout]=await Promise.all([read('src/lib/dashboard-preview.ts'),read('src/app/dev/dashboard-preview/layout.tsx')]);
 assert.match(guard,/process\.env\.NODE_ENV!==['"]development['"]/);
 assert.match(guard,/notFound\(\)/);
 assert.doesNotMatch(guard,/NEXT_PUBLIC_|DASHBOARD_PREVIEW_ENABLED|PREVIEW_MODE/);
 assert.match(layout,/requireDevelopmentDashboardPreview\(\)/);
 assert.match(layout,/index:false/);
});

test('all five dashboard previews use synthetic fixtures and isolated routes',async()=>{
 const [fixtures,page,index]=await Promise.all([read('src/data/dashboard-preview-fixtures.ts'),read('src/components/development-dashboard-preview.tsx'),read('src/app/dev/dashboard-preview/page.tsx')]);
 for(const slug of ['super-admin','admin','artist','intermediary','collector']){
  assert.match(fixtures,new RegExp(`(?:'${slug}'|${slug}):`));
  assert.match(index,new RegExp(slug));
 }
 assert.match(page,/data-dashboard-preview="synthetic"/);
 assert.match(page,/DEVELOPMENT DEMO/);
 assert.match(page,/previewMode/);
 assert.match(fixtures,/DEMO-/);
});

test('preview implementation cannot query data or invoke privileged operations',async()=>{
 const paths=['src/lib/dashboard-preview.ts','src/data/dashboard-preview-fixtures.ts','src/components/development-dashboard-preview.tsx','src/app/dev/dashboard-preview/layout.tsx','src/app/dev/dashboard-preview/page.tsx','src/app/dev/dashboard-preview/[dashboard]/page.tsx'];
 const source=(await Promise.all(paths.map(read))).join('\n');
 for(const forbidden of [/from ['"][^'"]*supabase/i,/emergent_staging/i,/\.from\(/,/fetch\(/,/['"]use server['"]/,/requireRole\(/,/requirePermission\(/,/createClient\(/,/service_role/i,/process\.env\.(?!NODE_ENV)/])assert.doesNotMatch(source,forbidden);
 assert.doesNotMatch(source,/<form|\saction=|onClick=|onSubmit=/);
 assert.match(source,/DisabledAction/);
});

test('preview routes do not introduce route handlers or APIs',async()=>{
 const entries=await readdir('src/app/dev/dashboard-preview',{recursive:true});
 assert.ok(entries.includes('page.tsx'));
 assert.ok(entries.includes('[dashboard]\\page.tsx')||entries.includes('[dashboard]/page.tsx'));
 assert.equal(entries.some(entry=>/(^|[\\/])route\.(ts|tsx|js|jsx)$/.test(entry)),false);
});

test('real dashboard authorization remains intact',async()=>{
 const routes=['src/app/admin/page.tsx','src/app/artist/page.tsx','src/app/intermediary/page.tsx','src/app/account/page.tsx'];
 const source=(await Promise.all(routes.map(read))).join('\n');
 assert.ok((source.match(/requireRole\(/g)??[]).length>=4);
 assert.doesNotMatch(source,/dashboard-preview|previewMode/);
});
