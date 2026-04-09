import { test, expect } from '@playwright/test';
import { Navbar } from '../pages/components/navbar/navbar';
import * as path from 'path';
const artistState = path.join(process.cwd(), 'playwright/.auth/artist1.json');


test.use({ storageState: artistState })
test.describe("Profile Management(Happy Path)", () => {
    test("test", async ({ page }) => {
        await page.goto('https://beatza.me/home');
        await expect(page.getByRole('heading', { name: /Upload/i })).toBeVisible();
    })

})
