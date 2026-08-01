import { test, expect } from '@playwright/test';
test('protège les routes sans configuration Supabase', async ({ page }) => { await page.goto('/'); await expect(page.getByRole('heading', { name: 'Supabase n’est pas configuré' })).toBeVisible(); await expect(page.getByText('VITE_SUPABASE_URL')).toBeVisible(); });
