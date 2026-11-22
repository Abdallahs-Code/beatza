// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';
import { AuthForm } from '../pages/components/auth_form/auth_form';
import { LandingPage } from '../pages/landing_page';
import * as path from 'path';

import credentials from '../credentials.json'

for (const [userKey, userCreds] of Object.entries(credentials)) {
    const statePath = path.join(process.cwd(), `playwright/.auth/${userKey}.json`);

    setup(`Authenticate ${userKey}`, async ({ page }) => {
        await page.goto('https://beatza.me/');

        const landingPage = new LandingPage(page);
        await landingPage.signInBtn.click();

        const authForm = new AuthForm(page);
        await authForm.Login(userCreds.email, userCreds.password);

        // Wait for login to process
        await page.waitForTimeout(3000);
        if (userKey != 'admin') {
            await expect(page).toHaveURL('https://beatza.me/home');
        }
        await page.waitForLoadState('load');

        await page.context().storageState({ path: statePath });
        console.log(`✅ ${userKey} saved.`);
    });
}