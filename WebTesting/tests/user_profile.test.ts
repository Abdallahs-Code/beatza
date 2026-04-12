import * as path from 'path';
import { test, expect, type BrowserContext, type Page } from '@playwright/test';
import { Navbar } from '../pages/components/navbar/navbar';
import { ProfilePage } from '../pages/profile/profile_page'

const artistState = path.join(process.cwd(), 'playwright/.auth/artist2.json');
const artist1State = path.join(process.cwd(), 'playwright/.auth/artist1.json'); // Adjust file name if needed

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

test.describe("Cross Profile Visit", () => {
    let context1: BrowserContext;
    let context2: BrowserContext;
    let page1: Page;
    let page2: Page;
    let profileUrl1: string;
    let profileUrl2: string;

    test.beforeEach(async ({ browser }) => {
        // Setup Context 1 (Account 1 - using artistState)
        context1 = await browser.newContext({ storageState: artistState });
        page1 = await context1.newPage();

        // Setup Context 2 (Account 2 - using artist1State)
        context2 = await browser.newContext({ storageState: artist1State });
        page2 = await context2.newPage();

        // Navigate Account 1 to its profile and get URL
        await page1.goto('https://beatza.me/home');
        const navbar1 = new Navbar(page1);
        await navbar1.GoToProfilePage();
        profileUrl1 = page1.url();

        // Navigate Account 2 to its profile and get URL
        await page2.goto('https://beatza.me/home');
        const navbar2 = new Navbar(page2);
        await navbar2.GoToProfilePage();
        profileUrl2 = page2.url();
    });

    test.afterEach(async () => {
        // Clean up contexts after each test
        await context1.close();
        await context2.close();
    });

    test("Visit each other's profile using two accounts", async () => {
        // Cross-visit: Account 1 visits Account 2's profile
        await page1.goto(profileUrl2);

        // Cross-visit: Account 2 visits Account 1's profile
        await page2.goto(profileUrl1);

        // Assert that they successfully landed on each other's profiles
        await expect(page1).toHaveURL(profileUrl2);
        await expect(page2).toHaveURL(profileUrl1);
    });


});
