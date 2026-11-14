import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
import path from 'node:path';

const output=path.resolve('docs/integration/screenshots/catalogue-parity');
await mkdir(output,{recursive:true});
const browser=await chromium.launch({headless:true});
const results=[];
for(const {name,width,height} of [{name:'desktop-1440',width:1440,height:1000},{name:'tablet-768',width:768,height:1000},{name:'mobile-390',width:390,height:844}]){
  const page=await browser.newPage({viewport:{width,height},deviceScaleFactor:1});
  await page.emulateMedia({reducedMotion:'reduce'});
  await page.goto('http://localhost:3000/artworks?preview=approved-media',{waitUntil:'networkidle'});
  await page.evaluate(async()=>{for(let y=0;y<document.body.scrollHeight;y+=600){window.scrollTo(0,y);await new Promise(resolve=>setTimeout(resolve,35))}window.scrollTo(0,0)});
  await page.waitForTimeout(150);
  await page.screenshot({path:path.join(output,`nextjs-${name}.png`),fullPage:true});
  results.push({name,title:await page.locator('h1').innerText(),works:await page.getByTestId('browse-result-count').innerText(),gridColumns:await page.getByTestId('browse-grid').evaluate(node=>getComputedStyle(node).gridTemplateColumns),overflow:await page.evaluate(()=>document.documentElement.scrollWidth-document.documentElement.clientWidth),fixture:await page.locator('.catalogue-fixture-notice').innerText()});
  await page.close();
}
await browser.close();
await writeFile(path.join(output,'capture-results.json'),JSON.stringify(results,null,2));
console.log(JSON.stringify(results,null,2));
