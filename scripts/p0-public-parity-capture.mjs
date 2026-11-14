import {mkdir} from 'node:fs/promises';
import path from 'node:path';
import {chromium} from 'playwright';

const base=process.env.PLAYWRIGHT_BASE_URL||'http://localhost:3000';
const output=path.resolve('docs/integration/screenshots/p0-public-parity');
await mkdir(output,{recursive:true});
const routes=[['home','/'],['catalogue','/artworks?preview=approved-media'],['artwork-detail','/artworks/00000000-0000-4000-8000-000000000001?preview=approved-media'],['artists','/artists?preview=approved-media'],['collections','/collections?preview=approved-media']];
const browser=await chromium.launch({headless:true});
for(const [width,height,label] of [[1440,1000,'desktop'],[768,1024,'tablet'],[390,844,'mobile']]){for(const [name,route] of routes){const page=await browser.newPage({viewport:{width,height}});await page.goto(`${base}${route}`,{waitUntil:'networkidle'});await page.evaluate(async()=>{for(let y=0;y<document.documentElement.scrollHeight;y+=innerHeight){scrollTo(0,y);await new Promise(resolve=>setTimeout(resolve,35))}scrollTo(0,0)});await page.screenshot({path:path.join(output,`${name}-${label}.png`),fullPage:true});await page.close()}}
await browser.close();
console.log(`P0 visual evidence: ${routes.length*3} screenshots captured in ${output}`);
