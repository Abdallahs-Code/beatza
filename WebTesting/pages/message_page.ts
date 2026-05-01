import { Page, Locator } from '@playwright/test';

export class MessagePage {
    readonly page: Page;

    readonly pageTitle: Locator;
    readonly newMessageButton: Locator;

    readonly conversationList: Locator;
    readonly selectedConversation: Locator;
    readonly conversationHeader: Locator;
    readonly conversationActions: Locator;
    readonly markAsUnreadButton: Locator;
    readonly deleteConversationButton: Locator;
    readonly blockUserButton: Locator;
    readonly reportUserButton: Locator;

    readonly messageThread: Locator;
    readonly messageComposer: Locator;
    readonly messageInput: Locator;
    readonly sendButton: Locator;

    constructor(page: Page) {
        this.page = page;

        this.pageTitle = page.getByRole('heading', { name: 'Messages', exact: true });
        this.newMessageButton = page.getByRole('button', { name: 'New' });

        this.conversationList = page.locator('div.w-\[30%\]');
        this.selectedConversation = page.locator('div.w-\[67%\]');
        this.conversationHeader = page.getByRole('link', { name: /beatzatesting|Messages/i }).first();
        this.conversationActions = page.locator('div.flex.items-center.gap-2').filter({ has: page.getByRole('button', { name: 'Mark as unread' }) });
        this.markAsUnreadButton = page.getByRole('button', { name: 'Mark as unread' });
        this.deleteConversationButton = page.getByRole('button').filter({ has: page.locator('svg') }).nth(0);
        this.blockUserButton = page.getByRole('button', { name: 'Block' });
        this.reportUserButton = page.getByRole('button', { name: 'Report' });

        this.messageThread = page.locator('div.flex-1.overflow-y-auto.scrollbar-hide');
        this.messageComposer = page.locator('div.flex.flex-col.gap-3.mb-5.mt-20');
        this.messageInput = page.locator('textarea.w-full.h-25.bg-off-black');
        this.sendButton = page.locator('div.flex.justify-end button:has-text("Send")');
    }

    getConversationByName(name: string) {
        return this.conversationList.getByText(name, { exact: true });
    }

    getConversationPreviewByText(text: string) {
        return this.conversationList.getByText(text, { exact: false });
    }

    getMessageByText(text: string) {
        return this.messageThread.getByText(text, { exact: false });
    }

    async openConversation(name: string) {
        await this.getConversationByName(name).click();
    }

    async startNewMessage() {
        await this.newMessageButton.click();
    }

    async fillMessage(message: string) {
        await this.messageInput.fill(message);
    }

    async sendMessage(message: string) {
        await this.fillMessage(message);
        await this.sendButton.click();
    }

    async markCurrentConversationAsUnread() {
        await this.markAsUnreadButton.click();
    }

    async deleteCurrentConversation() {
        await this.deleteConversationButton.click();
    }

    async blockCurrentUser() {
        await this.blockUserButton.click();
    }

    async reportCurrentUser() {
        await this.reportUserButton.click();
    }
}
