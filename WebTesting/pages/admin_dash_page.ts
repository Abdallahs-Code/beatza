import { Page, Locator } from '@playwright/test';

export class AdminDashPage {
    page: Page;
    searchInput: Locator;

    constructor(page: Page) {
        this.page = page;
        this.searchInput = page.getByPlaceholder('Search by username or email...');
    }

    async searchUser(text: string) {
        await this.searchInput.fill(text);
        // Wait for search results
        await this.page.waitForTimeout(1000);
    }

    async suspendUser(email: string) {
        const row = this.page.locator('tr').filter({ hasText: email });
        const suspendBtn = row.getByTitle('Suspend');
        await suspendBtn.click();
    }

    async unsuspendUser(email: string) {
        const row = this.page.locator('tr').filter({ hasText: email });
        // Adjust the title if the button is named "Activate", "Restore", or something else in the DOM
        const unsuspendBtn = row.getByTitle('Unsuspend');
        await unsuspendBtn.click();
    }
}
