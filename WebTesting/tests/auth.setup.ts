// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';
import { AuthForm } from '../pages/components/auth_form/auth_form';
import { LandingPage } from '../pages/landing_page';


// Define the file paths for your 4 test accounts
const artist1File = 'playwright/.auth/artist1.json';
const artist2File = 'playwright/.auth/artist2.json';
const listener1File = 'playwright/.auth/listener1.json';
const listener2File = 'playwright/.auth/listener2.json';

setup('Authenticate Artist 1', async ({ page }) => {
    await page.goto('https://beatza.me/');

    const landingPage = new LandingPage(page)
    await landingPage.signInBtn.click()

    const signUpForm = new AuthForm(page)
    const testEmail = `beatzatesting+loggedin@gmail.com`;
    await signUpForm.Login(testEmail, "Beatza@123")

    await expect()
    await page.context().storageState({ path: artist1File });
    console.log('✅ Artist 1 saved.');
});

setup('Authenticate Artist 2', async ({ page }) => {
    await page.goto('/login');
    console.log('🛑 Paused! Log in as ARTIST 2.');

    await page.context().storageState({ path: artist2File });
    console.log('✅ Artist 2 saved.');
});

setup('Authenticate Listener 1', async ({ page }) => {
    await page.goto('/login');
    console.log('🛑 Paused! Log in as LISTENER 1.');

    await page.context().storageState({ path: listener1File });
    console.log('✅ Listener 1 saved.');
});

setup('Authenticate Listener 2', async ({ page }) => {
    await page.goto('/login');
    console.log('🛑 Paused! Log in as LISTENER 2.');

    await page.context().storageState({ path: listener2File });
    console.log('✅ Listener 2 saved.');
});