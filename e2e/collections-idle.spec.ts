import {expect,test,type Page} from '@playwright/test';

const viewports=[
  {name:'desktop',width:1440,height:1000},
  {name:'tablet',width:768,height:1024},
  {name:'mobile',width:390,height:844},
] as const;

type NavigationTrace={documents:string[];frames:string[];hydrationErrors:string[]};

function traceNavigations(page:Page):NavigationTrace{
  const trace:NavigationTrace={documents:[],frames:[],hydrationErrors:[]};
  page.on('request',request=>{
    if(request.isNavigationRequest()&&request.resourceType()==='document')trace.documents.push(request.url());
  });
  page.on('framenavigated',frame=>{
    if(frame===page.mainFrame())trace.frames.push(frame.url());
  });
  page.on('pageerror',error=>trace.hydrationErrors.push(error.message));
  page.on('console',message=>{
    if(message.type()==='error'&&/hydrat|server rendered html|client properties/i.test(message.text()))trace.hydrationErrors.push(message.text());
  });
  return trace;
}

for(const viewport of viewports){
  test(`collections-idle: ${viewport.name} remains on one document for 15 seconds`,async({browser,baseURL})=>{
    test.setTimeout(45_000);
    const context=await browser.newContext({viewport});
    const page=await context.newPage();
    const trace=traceNavigations(page);

    const response=await page.goto(`${baseURL}/collections`,{waitUntil:'networkidle'});
    expect(response?.status()).toBe(200);
    const settledUrl=page.url();
    await page.waitForTimeout(15_000);

    expect(page.url()).toBe(settledUrl);
    expect(trace.documents).toEqual([`${baseURL}/collections`]);
    expect(trace.frames.length).toBeLessThanOrEqual(2);
    expect(trace.frames.every(url=>url===`${baseURL}/collections`)).toBe(true);
    expect(trace.hydrationErrors).toEqual([]);
    await expect(page.locator('h1')).toHaveText('Collections');
    await expect(page.locator('html')).not.toHaveCSS('overflow-x','scroll');

    if(viewport.name==='mobile'){
      await page.locator('.mobile-menu>summary').click();
      await expect(page.locator('.mobile-menu>nav')).toBeVisible();
    }else{
      await page.getByRole('link',{name:'Artworks',exact:true}).first().click();
      await expect(page).toHaveURL(/\/artworks/);
    }
    await context.close();
  });
}

test('collections-idle: adjacent public routes do not self-navigate',async({browser,baseURL})=>{
  test.setTimeout(45_000);
  for(const route of ['/','/artworks','/artists','/collections']){
    const context=await browser.newContext({viewport:{width:1440,height:1000}});
    const page=await context.newPage();
    const trace=traceNavigations(page);
    await page.goto(`${baseURL}${route}`,{waitUntil:'networkidle'});
    const settledUrl=page.url();
    await page.waitForTimeout(2_000);
    expect(page.url(),route).toBe(settledUrl);
    expect(trace.documents.at(-1),route).toBe(`${baseURL}${route}`);
    expect(trace.hydrationErrors,route).toEqual([]);
    await context.close();
  }
});
