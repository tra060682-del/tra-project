import {mkdir} from 'node:fs/promises';
import {chromium} from '@playwright/test';

const base=process.env.PLAYWRIGHT_BASE_URL||'http://localhost:3000';
const output='docs/integration/screenshots/phase5';
await mkdir(output,{recursive:true});
const browser=await chromium.launch();
for(const width of [1440,768,390]){
 const page=await browser.newPage({viewport:{width,height:1000}});
 await page.goto(`${base}/design-preview`,{waitUntil:'networkidle'});
 const foundation=page.locator('.dashboard-layout').first();
 await foundation.scrollIntoViewIfNeeded();
 await foundation.screenshot({path:`${output}/dashboard-foundation-${width}.png`});
 await page.goto(`${base}/artist`,{waitUntil:'networkidle'});
 await page.screenshot({path:`${output}/protected-dashboard-gate-${width}.png`,fullPage:true});
 await page.close();
}
await browser.close();
