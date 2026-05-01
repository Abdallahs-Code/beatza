import * as path from 'path';
import { test, expect } from '@playwright/test';
import { ProfilePage } from '../pages/profile/profile_page';
import { Navbar } from '../pages/components/navbar/navbar';
import { MessagePage } from '../pages/message_page';

// Adjust file paths to your saved auth states for two different users
const senderState = path.join(process.cwd(), 'playwright/.auth/artist1.json');
const receiverState = path.join(process.cwd(), 'playwright/.auth/artist2.json');

test.describe('Messaging flow', () => {
    test.setTimeout(90000);

    test('Send a message from profile and verify in recipient navbar and message page', async ({ browser }) => {
        // 1. Create a context for the receiver to get their profile URL
        const receiverContext = await browser.newContext({ storageState: receiverState });
        const receiverPage = await receiverContext.newPage();

        await receiverPage.goto('https://beatza.me/home');
        const receiverNavbar = new Navbar(receiverPage);

        // Go to receiver's profile to capture their URL
        await receiverNavbar.profileBtn.click();
        await receiverNavbar.profileDropdown.profile.click();

        await receiverPage.waitForLoadState('networkidle');
        const receiverProfileUrl = receiverPage.url();

        // 2. Create a context for the sender
        const senderContext = await browser.newContext({ storageState: senderState });
        const senderPage = await senderContext.newPage();

        // Sender directly navigates to receiver's profile
        await senderPage.goto(receiverProfileUrl);
        const senderProfilePage = new ProfilePage(senderPage);

        // Sender clicks the send message button
        await senderProfilePage.sendMsgBtn.waitFor({ state: 'visible' });
        await senderProfilePage.sendMsgBtn.click();

        // Type the message in the dialog
        const uniqueMessageText = `Hello, this is an automated test message from the sender ${Date.now()}`;
        await senderProfilePage.msgInput.fill(uniqueMessageText);
        await senderProfilePage.dialogSendBtn.click();

        // Allow some time for the message to be dispatched
        await senderPage.waitForTimeout(3000);

        // 3. Receiver goes back home to check their navbar for messages
        await receiverPage.goto('https://beatza.me/home');
        await receiverNavbar.messages.click();

        // Verify the message preview appears in the dropdown
        await expect(receiverPage.getByText(uniqueMessageText).first()).toBeVisible({ timeout: 10000 });

        // Click "View all messages" in the dropdown
        await receiverNavbar.viewAllMessagesLink.click();

        // 4. Verify message in the MessagePage
        const messagePage = new MessagePage(receiverPage);
        await expect(messagePage.pageTitle).toBeVisible();
        await expect(messagePage.getMessageByText(uniqueMessageText).first()).toBeVisible();

        // Clean up contexts
        await senderContext.close();
        await receiverContext.close();
    });
});