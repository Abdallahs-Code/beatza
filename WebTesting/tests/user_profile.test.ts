import * as path from 'path';
import { test, expect } from '@playwright/test';
import { Navbar } from '../pages/components/navbar/navbar';
import { ProfileDropdown } from '../pages/components/navbar/profile_dropdown';
import { ProfilePage } from '../pages/profile/profile_page'

const artistState = path.join(process.cwd(), 'playwright/.auth/artist1.json');


test.use({ storageState: artistState })
test.describe("Profile Management(Happy Path)", () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('https://beatza.me/home');
        const navbar = new Navbar(page);
        await navbar.GoToProfilePage();
    });
    test("profile Pic Upload", async ({ page }) => {
        // const avatarImage = page.getByTestId('user-avatar-img');
        // const originalSrc = await avatarImage.getAttribute('src');

        const profilePage = new ProfilePage(page)
        const fileChooserPromise = page.waitForEvent('filechooser');
        await profilePage.UploadProfileImg()
        const fileChooser = await fileChooserPromise;
        const filePath = path.join(process.cwd(), 'upload assets', 'profile_pic.jpg');
        await fileChooser.setFiles(filePath);
        await page.waitForTimeout(1000)
        // await expect(page.locator).toHaveScreenshot('updated-avatar.png');
        await profilePage.DeleteProfileImg()
        // await expect(page.getByRole('button', { name: /Upload/i })).toBeVisible();
    })

})
