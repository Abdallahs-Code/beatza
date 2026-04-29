// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';
import { AuthForm } from '../pages/components/auth_form/auth_form';
import { LandingPage } from '../pages/landing_page';

import credentials from '../credentials.json'

// Define the file paths for your 4 test accounts
const artist1File = 'playwright/.auth/artist1.json';
const artist2File = 'playwright/.auth/artist2.json';
const listener1File = 'playwright/.auth/artist3.json';
const listener2File = 'playwright/.auth/listener2.json';
const listener3File = 'playwright/.auth/listener3.json';
const listener4File = 'playwright/.auth/listener4.json';

setup('Authenticate Artist 1', async ({ page }) => {
    await page.goto('https://beatza.me/');

    const landingPage = new LandingPage(page)
    await landingPage.signInBtn.click()

    const signUpForm = new AuthForm(page)
    await signUpForm.Login(credentials.artist1.email, credentials.artist1.password)

    await expect(page).toHaveURL('https://beatza.me/home');
    await page.waitForLoadState('load');

    await page.context().storageState({ path: artist1File });
    console.log('✅ Artist 1 saved.');
});

setup('Authenticate Artist 2', async ({ page }) => {
    await page.goto('https://beatza.me/');

    const landingPage = new LandingPage(page)
    await landingPage.signInBtn.click()

    const signUpForm = new AuthForm(page)
    await signUpForm.Login(credentials.artist2.email, credentials.artist2.password)
    await page.waitForTimeout(5000)
    await expect(page).toHaveURL('https://beatza.me/home');
    await page.waitForLoadState('load');


    await page.context().storageState({ path: artist2File });
    console.log('✅ Artist 2 saved.');
});

setup('Authenticate artist 3', async ({ page }) => {
    await page.goto('https://beatza.me/');
    const landingPage = new LandingPage(page)
    await landingPage.signInBtn.click()

    const signUpForm = new AuthForm(page)
    await signUpForm.Login(credentials.artist3.email, credentials.artist3.password)
    await page.waitForTimeout(1000)

    await expect(page).toHaveURL('https://beatza.me/home');
    await page.waitForLoadState('load');



    await page.context().storageState({ path: listener1File });
    console.log('✅ artist 3 saved.');
});

setup('Authenticate Listener 2', async ({ page }) => {
    await page.goto('https://beatza.me/');

    const landingPage = new LandingPage(page)
    await landingPage.signInBtn.click()

    const signUpForm = new AuthForm(page)
    await signUpForm.Login(credentials.listener2.email, credentials.listener2.password)
    await page.waitForTimeout(1000)

    await expect(page).toHaveURL('https://beatza.me/home');
    await page.waitForLoadState('load');


    await page.context().storageState({ path: listener2File });
    console.log('✅ Listener 2 saved.');
});