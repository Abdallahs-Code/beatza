import { test, expect } from '@playwright/test';
import { AdminDashPage } from '../pages/admin_dash_page';
import { AuthForm } from '../pages/components/auth_form/auth_form';
import { LandingPage } from '../pages/landing_page';
import * as path from 'path';

const adminState = path.join(process.cwd(), 'playwright/.auth/admin.json');

test.describe("Admin Operations", () => {
    test("Suspend a user and verify login failure", async ({ browser }) => {
        test.setTimeout(60000);

        const adminContext = await browser.newContext({ storageState: adminState });
        const adminPage = await adminContext.newPage();

        await adminPage.goto('https://beatza.me/admin-dash/profiles-manage');

        const adminDash = new AdminDashPage(adminPage);
        const testUserEmail = "beatzatesting+1774020544155@gmail.com";

        await adminDash.searchUser(testUserEmail);
        await adminDash.suspendUser(testUserEmail);

        await expect(adminPage.locator('tr').filter({ hasText: testUserEmail }).getByText('suspended', { exact: true })).toBeVisible();

        const blockedUserContext = await browser.newContext();
        const userPage = await blockedUserContext.newPage();

        await userPage.goto('https://beatza.me');
        const landingPage = new LandingPage(userPage);
        await userPage.waitForLoadState();
        await landingPage.signInBtn.click();

        const loginForm = new AuthForm(userPage);
        await loginForm.Login(testUserEmail, "Beatza@123");

        await expect(userPage.getByText(/banned/i)).toBeVisible();

        await blockedUserContext.close();

        await adminDash.searchUser(testUserEmail);
        await adminDash.unsuspendUser(testUserEmail);

        await expect(adminPage.locator('tr').filter({ hasText: testUserEmail }).getByText('active', { exact: true })).toBeVisible();

        const activeUserContext = await browser.newContext();
        const activeUserPage = await activeUserContext.newPage();

        await activeUserPage.goto('https://beatza.me');
        const activeLandingPage = new LandingPage(activeUserPage);
        await activeUserPage.waitForLoadState();
        await activeLandingPage.signInBtn.click();

        const activeLoginForm = new AuthForm(activeUserPage);
        await activeLoginForm.Login(testUserEmail, "Beatza@123");

        await expect(activeUserPage).toHaveURL(/\/home/);

        await activeUserContext.close();
        await adminContext.close();
    });
});
