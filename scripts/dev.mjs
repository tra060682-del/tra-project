import {spawn,spawnSync} from 'node:child_process';
// Accept optional preview-daemon flags while preserving normal Next.js development.
const args=process.argv.slice(2).filter(a=>a!=='--strictPort').map(a=>a==='--host'?'--hostname':a);
const child=spawn(process.execPath,['node_modules/next/dist/bin/next','dev',...args],{stdio:'inherit'});
let stopping=false;
function stop(signal){
  if(stopping)return;
  stopping=true;
  if(process.platform==='win32')spawnSync('taskkill',['/pid',String(child.pid),'/T','/F'],{stdio:'ignore'});
  else child.kill(signal);
}
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>stop(signal));
child.on('exit',code=>process.exit(code??1));
