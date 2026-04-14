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
    let userContext1: BrowserContext;
    let userContext2: BrowserContext;
    let user1: Page;
    let user2: Page;
    let user1ProfileUrl: string;
    let user2ProfileUrl: string;

    test.beforeEach(async ({ browser }) => {
        // Setup Context 1 (Account 1 - using artistState)
        userContext1 = await browser.newContext({ storageState: artistState });
        user1 = await userContext1.newPage();

        // Setup Context 2 (Account 2 - using artist1State)
        userContext2 = await browser.newContext({ storageState: artist1State });
        user2 = await userContext2.newPage();

        // Navigate Account 1 to its profile and get URL
        await user1.goto('https://beatza.me/home');
        const navbar1 = new Navbar(user1);
        await navbar1.GoToProfilePage();
        await user1.waitForURL(/\/profile\/[a-zA-Z0-9]+/); // Ensure navigation finishes before capturing URL
        user1ProfileUrl = user1.url();
        console.log(user1ProfileUrl)

        // Navigate Account 2 to its profile and get URL
        await user2.goto('https://beatza.me/home');
        const navbar2 = new Navbar(user2);
        await navbar2.GoToProfilePage();
        await user2.waitForURL(/\/profile\/[a-zA-Z0-9]+/); // Ensure navigation finishes before capturing URL
        user2ProfileUrl = user2.url();
        console.log(user2ProfileUrl)
    });

    test.afterEach(async () => {
        // Clean up contexts after each test
        await userContext1.close();
        await userContext2.close();
    });

    test("User blocks and unblocks another user", async () => {
        test.setTimeout(50000);
        const user1ProfilePage = new ProfilePage(user1);
        const user2ProfilePage = new ProfilePage(user2);

        // --- User 1 blocks User 2 ---

        // User 1 visits User 2's profile
        await user1.goto(user2ProfileUrl);
        await expect(user1).toHaveURL(user2ProfileUrl);
        await user1.waitForTimeout(2000);

        // User 1 uses the 'More' menu to block User 2
        await user1ProfilePage.moreBtn.click();
        await user1.waitForTimeout(500);
        await user1ProfilePage.blockBtn.click();

        // Ensure the Block modal/form is filled and submitted
        await user1ProfilePage.blockForm.SubmitBlock();
        await user1.waitForTimeout(2000);

        await user2.goto(user1ProfileUrl);
        await expect(user2).toHaveURL(user1ProfileUrl);
        await user2.waitForTimeout(2000);

        // Try to follow User 1 as User 2 (Blocked user)
        const initialFollowersText = await user2.locator('a:has(p:text-is("Followers")) span').innerText();
        const initialFollowers = parseInt(initialFollowersText.replace(/,/g, ''), 10) || 0;

        await user2ProfilePage.ClickFollowBtn();
        await user2.waitForTimeout(2000);

        // Refresh and assert the follower count did not increase
        await user2.reload();
        await user2.waitForTimeout(2000);

        const finalFollowersText = await user2.locator('a:has(p:text-is("Followers")) span').innerText();
        const finalFollowers = parseInt(finalFollowersText.replace(/,/g, ''), 10) || 0;
        await expect(finalFollowers).toBe(initialFollowers);


        await user1.goto(user2ProfileUrl);
        await expect(user1).toHaveURL(user2ProfileUrl);
        await user1.waitForTimeout(2000); // Wait to fetch info

        await user1ProfilePage.moreBtn.click();
        await user1.waitForTimeout(500);

        await user1ProfilePage.blockBtn.click();
    });

    test("Visit each other's profile using two accounts", async () => {
        test.setTimeout(50000);
        const user1ProfilePage = new ProfilePage(user1);
        const user2ProfilePage = new ProfilePage(user2);

        // --- User 1 follows User 2 ---

        // Get initial follower count of User 2 from User 2's own perspective (already on their profile)
        await user2.waitForTimeout(2000); // Wait to fetch info at test start
        const initialFollowersUser2Text = await user2.locator('a:has(p:text-is("Followers")) span').innerText();
        const initialFollowersUser2 = parseInt(initialFollowersUser2Text.replace(/,/g, ''), 10) || 0;

        // User 1 visits User 2's profile and clicks follow
        await user1.goto(user2ProfileUrl);
        await expect(user1).toHaveURL(user2ProfileUrl);
        await user1.waitForTimeout(1000); // Wait for React hydration
        await user1ProfilePage.ClickFollowBtn();

        // User 1 refreshes their own profile to see the update
        await user2.reload();

        await user2.waitForTimeout(2000);

        // Assert User 2's followers increased by 1
        const finalFollowersUser2Text = await user2.locator('a:has(p:text-is("Followers")) span').innerText();
        const finalFollowersUser2 = parseInt(finalFollowersUser2Text.replace(/,/g, ''), 10) || 0;
        await expect(finalFollowersUser2).toBe(initialFollowersUser2 + 1);


        // --- User 2 follows User 1 ---

        // Navigate User 1 back to their own profile first to get the initial count
        await user1.goto(user1ProfileUrl);
        await user1.waitForTimeout(2000); // Wait to fetch info
        const initialFollowersUser1Text = await user1.locator('a:has(p:text-is("Followers")) span').innerText();
        const initialFollowersUser1 = parseInt(initialFollowersUser1Text.replace(/,/g, ''), 10) || 0;

        // User 2 visits User 1's profile and clicks follow
        await user2.goto(user1ProfileUrl);
        await expect(user2).toHaveURL(user1ProfileUrl);
        await user2.waitForTimeout(1000); // Wait for React hydration
        await user2ProfilePage.ClickFollowBtn();


        // User 1 refreshes their own profile to see the update
        await user1.reload();

        await user1.waitForTimeout(2000);

        // Assert User 1's followers increased by 1
        const finalFollowersUser1Text = await user1.locator('a:has(p:text-is("Followers")) span').innerText();
        const finalFollowersUser1 = parseInt(finalFollowersUser1Text.replace(/,/g, ''), 10) || 0;
        await expect(finalFollowersUser1).toBe(initialFollowersUser1 + 1);


        // --- User 1 unfollows User 2 ---

        // Navigate User 2 back to their own profile first to get the baseline count before unfollowing
        await user2.goto(user2ProfileUrl);
        await user2.waitForTimeout(2000); // Wait to fetch info
        const peakFollowersUser2Text = await user2.locator('a:has(p:text-is("Followers")) span').innerText();
        const peakFollowersUser2 = parseInt(peakFollowersUser2Text.replace(/,/g, ''), 10) || 0;

        // User 1 visits User 2's profile and clicks follow (which acts as unfollow toggle)
        await user1.goto(user2ProfileUrl);
        await expect(user1).toHaveURL(user2ProfileUrl);
        await user1.waitForTimeout(1000); // Wait for React hydration
        await user1ProfilePage.ClickFollowBtn();

        // User 1 refreshes their own profile to see the update
        await user2.reload();

        await user2.waitForTimeout(2000);
        // Assert User 2's followers decreased by 1
        const unfollowedFollowersUser2Text = await user2.locator('a:has(p:text-is("Followers")) span').innerText();
        const unfollowedFollowersUser2 = parseInt(unfollowedFollowersUser2Text.replace(/,/g, ''), 10) || 0;
        await expect(unfollowedFollowersUser2).toBe(peakFollowersUser2 - 1);


        // --- User 2 unfollows User 1 ---

        // Navigate User 1 back to their own profile first to get the baseline count before unfollowing
        await user1.goto(user1ProfileUrl);
        await user1.waitForTimeout(2000); // Wait to fetch info
        const peakFollowersUser1Text = await user1.locator('a:has(p:text-is("Followers")) span').innerText();
        const peakFollowersUser1 = parseInt(peakFollowersUser1Text.replace(/,/g, ''), 10) || 0;

        // User 2 visits User 1's profile and clicks follow (which acts as unfollow toggle)
        await user2.goto(user1ProfileUrl);
        await expect(user2).toHaveURL(user1ProfileUrl);
        await user2.waitForTimeout(1000); // Wait for React hydration
        await user2ProfilePage.ClickFollowBtn();

        // User 1 refreshes their own profile to see the update
        await user1.waitForTimeout(2000);
        await user1.reload();

        await user1.waitForTimeout(2000);
        // Assert User 1's followers decreased by 1
        const unfollowedFollowersUser1Text = await user1.locator('a:has(p:text-is("Followers")) span').innerText();
        const unfollowedFollowersUser1 = parseInt(unfollowedFollowersUser1Text.replace(/,/g, ''), 10) || 0;
        await expect(unfollowedFollowersUser1).toBe(peakFollowersUser1 - 1);
    });

});
