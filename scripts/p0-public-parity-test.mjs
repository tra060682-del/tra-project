import assert from 'node:assert/strict';
import {chromium} from 'playwright';

const base=process.env.PLAYWRIGHT_BASE_URL||'http://localhost:3000';
const browser=await chromium.launch({headless:true});
const desktop=await browser.newPage({viewport:{width:1440,height:1000}});
await desktop.goto(base,{waitUntil:'networkidle'});
assert.match(await desktop.locator('h1').innerText(),/Original Indian Art/);
assert.equal(await desktop.locator('.em-home > section').count()>=12,true);
const artworkMenu=desktop.locator('.nav-group').filter({hasText:'Artworks'}).first();await artworkMenu.hover();await desktop.waitForTimeout(200);
assert.equal(await artworkMenu.getByRole('link',{name:'New Arrivals'}).isVisible(),true);
await desktop.locator('.header-search>summary').click();
await desktop.locator('#header-search').fill('Tagore');
await Promise.all([desktop.waitForURL(/artworks\?q=Tagore/),desktop.locator('.header-search button[type=submit]').click()]);

await desktop.goto(`${base}/artworks?preview=approved-media`,{waitUntil:'networkidle'});
assert.equal(await desktop.getByTestId('browse-result-count').innerText(),'26 works');
await desktop.getByTestId('filter-artform-madhubani').click();
await desktop.waitForURL(/artform=Madhubani/);assert.equal(await desktop.getByTestId('browse-result-count').innerText(),'1 work');
await desktop.getByTestId('filters-clear').click();
await desktop.getByTestId('browse-sort-select').selectOption('price_desc');
await desktop.waitForURL(/sort=price_desc/);
const artworkHref=await desktop.getByTestId('browse-grid').locator('a').first().getAttribute('href');
await desktop.goto(`${base}${artworkHref}`,{waitUntil:'networkidle'});
assert.match(await desktop.locator('main').innerText(),/Authenticity and certificate/);
await desktop.getByRole('button',{name:/View full image/}).click();assert.equal(await desktop.locator('.artwork-zoom-dialog').isVisible(),true);await desktop.getByRole('button',{name:'Close'}).click();

await desktop.goto(`${base}/artists?preview=approved-media`,{waitUntil:'networkidle'});assert.equal(await desktop.locator('.artist-directory-grid>a').count(),6);await desktop.locator('.artist-directory-grid>a').first().click();await desktop.waitForURL(/\/artists\/reference-/);assert.match(await desktop.locator('main').innerText(),/HERITAGE VISUAL REFERENCE/);
await desktop.goto(`${base}/collections?preview=approved-media`,{waitUntil:'networkidle'});assert.equal(await desktop.locator('.collection-editorial-grid>a').count(),3);await desktop.locator('.collection-editorial-grid>a').first().click();await desktop.waitForURL(/\/collections\/reference-/);assert.match(await desktop.locator('main').innerText(),/Explore the works/);
for(const route of ['/contact','/login']){const response=await desktop.goto(`${base}${route}`,{waitUntil:'networkidle'});assert.ok(response&&response.status()<400,route)}

for(const width of [768,390]){const page=await browser.newPage({viewport:{width,height:900}});for(const route of ['/','/artworks?preview=approved-media','/artists?preview=approved-media','/collections?preview=approved-media']){await page.goto(`${base}${route}`,{waitUntil:'networkidle'});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth-document.documentElement.clientWidth),0,`${width}px overflow on ${route}`)}if(width===390){await page.goto(base);await page.locator('.mobile-menu>summary').click();assert.equal(await page.locator('.mobile-menu>nav').isVisible(),true);await page.locator('.mobile-nav-group').first().locator('summary').click();assert.equal(await page.getByRole('link',{name:'New Arrivals'}).isVisible(),true)}await page.close()}
await browser.close();
console.log('P0 public parity browser checks: 31 passed');
