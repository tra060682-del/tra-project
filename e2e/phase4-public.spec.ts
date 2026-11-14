import {expect,test} from '@playwright/test';

const routes=[
  ['/',/original indian art/i],['/artworks',/browse original art/i],['/artists',/our artists/i],
  ['/collections',/^collections$/i],['/auctions',/rare works/i],['/journal',/stories, practices/i],
  ['/legal',/clear terms/i],['/certificates/verify',/verify a certificate/i],['/art-advisory',/find art that belongs/i],
  ['/commissions',/work made with purpose/i],['/corporate-art',/art for places/i],['/resale',/careful route/i],['/contact',/talk about art/i],
] as const;

test.describe('Phase 4 public integration',()=>{
  for(const [path,heading] of routes)test(`${path} renders an honest public state`,async({page})=>{const response=await page.goto(path);expect(response?.status()).toBeLessThan(500);await expect(page.getByRole('heading',{name:heading}).first()).toBeVisible();await expect(page.locator('body')).not.toContainText('Illustrative artist')});

  test('catalogue search is addressable and staged data is not exposed',async({page})=>{await page.goto('/artworks?q=nonexistent-phase4-record');await expect(page).toHaveURL(/q=nonexistent-phase4-record/);await expect(page.getByText(/staged records have not been promoted|no (?:art)?works match/i)).toBeVisible()});

  test('certificate verification accurately remains disabled',async({page})=>{await page.goto('/certificates/verify');await expect(page.getByRole('button',{name:/verify certificate/i})).toBeDisabled();await expect(page.getByText(/have not been applied/i)).toBeVisible()});

  test('public imagery has alt text and enquiry controls have labels',async({page})=>{await page.goto('/art-advisory');const app=page.locator('main');expect(await app.locator('img:not([alt])').count()).toBe(0);for(const control of await app.locator('input:not([type="hidden"]),textarea,button').all()){expect((await control.getAttribute('aria-label'))||(await control.innerText())||(await control.getAttribute('id')&&await page.locator(`label[for="${await control.getAttribute('id')}"]`).count())||(await control.evaluate(node=>Boolean(node.closest('label'))))).toBeTruthy()}});

  for(const viewport of [{width:1440,height:1000},{width:768,height:1024},{width:390,height:844}])test(`public routes have no overflow at ${viewport.width}px`,async({page})=>{await page.setViewportSize(viewport);for(const [path] of routes){await page.goto(path);const size=await page.evaluate(()=>({scroll:document.documentElement.scrollWidth,client:document.documentElement.clientWidth}));expect(size.scroll,`${path} overflow`).toBeLessThanOrEqual(size.client+1)}});
});
