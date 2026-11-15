import {test,expect,type Page} from '@playwright/test';

const previews=[
 ['super-admin','Platform overview'],
 ['admin','Operations overview'],
 ['artist','Your studio'],
 ['intermediary','Representation workspace'],
 ['collector','Your collection journey'],
] as const;

function watchForbiddenRequests(page:Page){
 const requests:string[]=[];
 page.on('request',request=>{if(/\/api\/|supabase|emergent_staging/i.test(request.url()))requests.push(request.url())});
 return requests;
}

for(const [slug,title] of previews)test(`${slug} development dashboard is synthetic and read-only`,async({page})=>{
 const forbidden=watchForbiddenRequests(page);
 await page.goto(`/dev/dashboard-preview/${slug}`);
 await expect(page.getByText('DEVELOPMENT DEMO',{exact:true})).toBeVisible();
 await expect(page.getByRole('heading',{name:title})).toBeVisible();
 await expect(page.locator('[data-dashboard-preview="synthetic"]')).toBeVisible();
 const controls=page.locator('.preview-disabled-actions button');
 await expect(controls.first()).toBeDisabled();
 expect(await controls.count()).toBeGreaterThanOrEqual(6);
 for(let index=0;index<await controls.count();index++)expect(await controls.nth(index).isDisabled()).toBe(true);
 await page.waitForTimeout(500);
 expect(forbidden).toEqual([]);
});

test('preview navigation switches among all five roles without entering real dashboards',async({page})=>{
 await page.goto('/dev/dashboard-preview/super-admin');
 for(const [slug,label] of [['super-admin','Super Admin'],['admin','Admin'],['artist','Artist Studio'],['intermediary','Intermediary'],['collector','Collector']] as const){
  await page.getByRole('navigation',{name:'Development dashboard previews'}).getByRole('link',{name:label,exact:true}).click();
  await expect(page).toHaveURL(new RegExp(`/dev/dashboard-preview/${slug}$`));
  await expect(page.getByText('DEVELOPMENT DEMO',{exact:true})).toBeVisible();
 }
});

for(const viewport of [{width:1440,height:1000},{width:768,height:900},{width:390,height:844}])test(`preview layout has no horizontal page overflow at ${viewport.width}px`,async({page})=>{
 await page.setViewportSize(viewport);
 await page.goto('/dev/dashboard-preview/artist');
 await expect(page.getByRole('heading',{name:'Your studio'})).toBeVisible();
 const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>document.documentElement.clientWidth);
 expect(overflow).toBe(false);
});
