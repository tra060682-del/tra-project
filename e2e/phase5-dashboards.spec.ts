import {test,expect} from '@playwright/test';

for(const route of ['/admin','/admin/access','/artist','/intermediary','/account','/workspace'])test(`anonymous access is denied for ${route}`,async({page})=>{await page.goto(route);await expect(page).toHaveURL(/\/login/);await expect(page.getByRole('heading',{name:/welcome back/i})).toBeVisible()});

for(const viewport of [{width:1440,height:1000},{width:768,height:900},{width:390,height:844}])test(`dashboard access gate has no horizontal overflow at ${viewport.width}px`,async({page})=>{await page.setViewportSize(viewport);await page.goto('/artist');const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>document.documentElement.clientWidth);expect(overflow).toBe(false)});
