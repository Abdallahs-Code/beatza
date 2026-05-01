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
        this.newMessageButton = page.getByTestId('messages-new-button');

        this.conversationList = page.getByTestId('messages-conversation-list');
        this.selectedConversation = page.getByTestId('messages-selected-conversation');
        this.conversationHeader = page.getByTestId('messages-conversation-header');
        this.conversationActions = page.getByTestId('messages-conversation-actions');
        this.markAsUnreadButton = page.getByTestId('messages-mark-unread-button');
        this.deleteConversationButton = page.getByTestId('messages-delete-button');
        this.blockUserButton = page.getByTestId('messages-block-button');
        this.reportUserButton = page.getByTestId('messages-report-button');

        this.messageThread = page.getByTestId('messages-thread');
        this.messageComposer = page.getByTestId('messages-composer');
        this.messageInput = page.getByTestId('messages-compose-input');
        this.sendButton = page.getByTestId('messages-send-button');
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
