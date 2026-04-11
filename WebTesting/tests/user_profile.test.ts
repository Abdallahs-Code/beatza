import * as path from 'path';
import { test, expect } from '@playwright/test';
import { Navbar } from '../pages/components/navbar/navbar';
import { ProfilePage } from '../pages/profile/profile_page'

const artistState = path.join(process.cwd(), 'playwright/.auth/artist2.json');


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
    test("header Pic Upload", async ({ page }) => {
        // const avatarImage = page.getByTestId('user-avatar-img');
        // const originalSrc = await avatarImage.getAttribute('src');

        const profilePage = new ProfilePage(page)
        const fileChooserPromise = page.waitForEvent('filechooser');
        await profilePage.UploadHeaderImg()
        const fileChooser = await fileChooserPromise;
        const filePath = path.join(process.cwd(), 'upload assets', 'header_pic.jpg');
        await fileChooser.setFiles(filePath);
        await page.waitForTimeout(1000)

        await expect(profilePage.headerImg).toHaveScreenshot('updated-avatar.png');

        await profilePage.DeleteCoverImg()

    })
    test("Edit Profile", async ({ page }) => {
        const profilePage = new ProfilePage(page)
        // await page.getByRole("button", { name: "Edit" })

        await profilePage.ClickEditBtn()
        await profilePage.editform.fillBasicInfo("edited name", "edited first", "edited last", "edited bio")
        await profilePage.editform.addNewLink("h.com")
        await profilePage.editform.addNewsupportLink("https://hey.com")
        await profilePage.editform.fillLocation("edited city", "edited country")
        await profilePage.editform.saveChangesBtn.click()

        await expect(page.getByRole('heading', { name: 'edited name' })).toBeVisible();
        await expect(page.getByText('edited city, edited country')).toBeVisible();
        await expect(page.getByRole('button', { name: 'Support edited name' })).toBeVisible();
        await expect(page.getByRole('link', { name: 'h.com' })).toBeVisible();

        await profilePage.ClickEditBtn()
        await profilePage.editform.fillBasicInfo("notedited name", "notedited first", "notedited last", "notedited bio")
        await profilePage.editform.removeLinks()
        await profilePage.editform.fillLocation("notedited city", "notedited country")

        await profilePage.editform.saveChangesBtn.click()
    })

})
