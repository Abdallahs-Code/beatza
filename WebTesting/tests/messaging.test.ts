import * as path from 'path';
import { test, expect } from '@playwright/test';
import { ProfilePage } from '../pages/profile/profile_page';
import { Navbar } from '../pages/components/navbar/navbar';
import { MessagePage } from '../pages/message_page';

// Adjust file paths to your saved auth states for two different users
const senderState = path.join(process.cwd(), 'playwright/.auth/listener2.json');
const receiverState = path.join(process.cwd(), 'playwright/.auth/listener3.json');

test.describe('Messaging flow', () => {
    test.setTimeout(90000);

    test('Send a message from profile and verify in recipient navbar and message page', async ({ browser }) => {
        const receiverContext = await browser.newContext({ storageState: receiverState });
        const receiverPage = await receiverContext.newPage();

        await receiverPage.goto('https://beatza.me/home');
        const receiverNavbar = new Navbar(receiverPage);

        await receiverNavbar.profileBtn.click();
        await receiverNavbar.profileDropdown.profile.click();

        await receiverPage.waitForLoadState('networkidle');
        const receiverProfileUrl = receiverPage.url();

        const senderContext = await browser.newContext({ storageState: senderState });
        const senderPage = await senderContext.newPage();

        await senderPage.goto(receiverProfileUrl);
        const senderProfilePage = new ProfilePage(senderPage);

        await senderProfilePage.sendMsgBtn.waitFor({ state: 'visible' });
        await senderProfilePage.sendMsgBtn.click();

        const uniqueMessageText = `Hello, this is an automated test message from the sender ${Date.now()}`;
        await senderProfilePage.msgInput.fill(uniqueMessageText);
        await senderProfilePage.dialogSendBtn.click();

        await senderPage.waitForTimeout(3000);

        await receiverPage.goto('https://beatza.me/home');
        await receiverNavbar.messages.click();

        await expect(receiverPage.getByText(uniqueMessageText).first()).toBeVisible({ timeout: 10000 });

        await receiverNavbar.viewAllMessagesLink.click();

        const messagePage = new MessagePage(receiverPage);

        await expect(messagePage.getMessageByText(uniqueMessageText).first()).toBeVisible();


        await senderContext.close();
        await receiverContext.close();
    });
});