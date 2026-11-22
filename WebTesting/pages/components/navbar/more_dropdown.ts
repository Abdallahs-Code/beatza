import { Page, Locator, expect } from '@playwright/test';

export class MoreDropdown {
    dropdownContainer: Locator;

    aboutUs: Locator;
    legal: Locator;
    copyright: Locator;
    support: Locator;
    keyboardShortcuts: Locator;
    subscription: Locator;
    settings: Locator;
    signOut: Locator;

    constructor(page: Page) {
        this.dropdownContainer = page.getByTestId('more_dropdown');
        this.aboutUs = this.dropdownContainer.getByTestId('about-us-item-link-btn');
        this.legal = this.dropdownContainer.getByTestId('legal-item-link-btn');
        this.copyright = this.dropdownContainer.getByTestId('copyright-item-link-btn');
        this.support = this.dropdownContainer.getByTestId('support-item-link-btn');
        this.keyboardShortcuts = this.dropdownContainer.getByTestId('keyboard-shortcuts-item-link-btn');
        this.subscription = this.dropdownContainer.getByTestId('subscription-item-link-btn');
        this.settings = this.dropdownContainer.getByTestId('settings-item-link-btn');
        this.signOut = this.dropdownContainer.getByTestId('sign-out-item-link-btn');
    }

    async expectVisible() {
        await expect(this.dropdownContainer).toBeVisible();
    }

    async expectHidden() {
        await expect(this.dropdownContainer).toBeHidden();
    }
    async ClickSignOut() {
        await this.signOut.click()
    }
}
