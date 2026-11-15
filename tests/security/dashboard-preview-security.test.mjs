import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const read=path=>readFile(path,'utf8');

test('preview shell disables real search, profile, notifications and commerce links',async()=>{
 const source=await read('src/components/dashboard-layout.tsx');
 assert.match(source,/!previewMode&&path/);
 assert.match(source,/Search is disabled in the development demo/);
 assert.match(source,/Profile actions are disabled in the development demo/);
 assert.match(source,/Notifications are disabled in the development demo/);
});

test('every synthetic control is disabled with an explicit safety reason',async()=>{
 const source=await read('src/components/development-dashboard-preview.tsx');
 assert.match(source,/DisabledAction/);
 assert.match(source,/No write, provider call or privileged operation is available/);
 assert.doesNotMatch(source,/<button(?![^>]*disabled)/);
});
