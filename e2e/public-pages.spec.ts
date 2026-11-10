import {expect, test} from '@playwright/test';

test.describe('public release smoke', () => {
  for (const [path, heading] of [
    ['/', /art/i],
    ['/artworks', /art worth living with/i],
    ['/join-as-artist', /your practice/i],
    ['/login', /welcome back/i],
  ] as const) {
    test(`${path} is available`, async ({page}) => {
      const response = await page.goto(path);
      expect(response?.status()).toBeLessThan(500);
      await expect(page.getByRole('heading', {name: heading}).first()).toBeVisible();
    });
  }

  test('admin is not anonymously accessible', async ({page}) => {
    await page.goto('/admin');
    await expect(page).not.toHaveURL(/\/admin$/);
    await expect(page).toHaveURL(/\/(login|access-denied)/);
  });

  test('artist registration exposes the required verified-account fields', async ({page}) => {
    await page.goto('/join-as-artist');
    await expect(page.getByLabel(/artist or studio name/i)).toBeVisible();
    await expect(page.getByLabel(/email address/i)).toHaveAttribute('type','email');
    await expect(page.getByLabel(/^password$/i)).toHaveAttribute('minlength','8');
    await expect(page.getByRole('button',{name:/create artist account/i})).toBeVisible();
  });

  test('login and artist workspace authorization are enforced', async ({page}) => {
    await page.goto('/login');
    await expect(page.getByLabel(/email address/i)).toBeVisible();
    await expect(page.getByLabel(/^password$/i)).toBeVisible();
    await page.goto('/artist');
    await expect(page).toHaveURL(/\/login/);
  });

  test('critical API rejects an untrusted origin', async ({request}) => {
    const response = await request.post('/api/bids', {
      headers: {origin: 'https://invalid.example'},
      data: {},
    });
    expect(response.status()).toBe(403);
  });
});
