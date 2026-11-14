import {expect,test} from '@playwright/test';
test('integration readiness dashboard denies anonymous access',async({page})=>{await page.goto('/admin/integrations');await expect(page).toHaveURL(/\/login/)});
for(const width of [1440,768,390])test(`integration readiness access boundary has no overflow at ${width}px`,async({page})=>{await page.setViewportSize({width,height:900});await page.goto('/admin/integrations');await expect(page.locator('body')).toBeVisible();const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>document.documentElement.clientWidth);expect(overflow).toBe(false)});
test('no public payment webhook endpoint is active',async({request})=>{const response=await request.post('/api/payments/webhook',{data:{synthetic:true}});expect(response.status()).toBe(404)});

