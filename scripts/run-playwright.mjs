import {spawn,spawnSync} from 'node:child_process';

const remoteBase = process.env.PLAYWRIGHT_BASE_URL;
let server;
const waitForServer = async url => {
  const deadline = Date.now()+120_000;
  while(Date.now()<deadline){
    try { const response=await fetch(url); if(response.status<500)return; } catch {}
    await new Promise(resolve=>setTimeout(resolve,500));
  }
  throw new Error(`Timed out waiting for ${url}`);
};
const stopTree = child => {
  if(!child?.pid)return;
  if(process.platform==='win32')spawnSync('taskkill',['/pid',String(child.pid),'/T','/F'],{stdio:'ignore'});
  else child.kill('SIGTERM');
};
try {
  if(!remoteBase){
    server=spawn(process.execPath,['node_modules/next/dist/bin/next','dev','-H','localhost'],{stdio:'inherit'});
    await waitForServer('http://localhost:3000');
  }
  const playwright=spawnSync(process.execPath,['node_modules/@playwright/test/cli.js','test'],{
    stdio:'inherit',env:{...process.env,PLAYWRIGHT_BASE_URL:remoteBase||'http://localhost:3000'},
  });
  if(playwright.error)throw playwright.error;
  process.exitCode=playwright.status??1;
} finally {
  stopTree(server);
}
process.exit(process.exitCode??1);
