import { Locator, expect } from '@playwright/test';

export class MoreDropdown {
    dropdownContainer: Locator;

    aboutUs: Locator;
    legal: Locator;
    copyright: Locator;
    mobileApps: Locator;
    artistMembership: Locator;
    newsroom: Locator;
    jobs: Locator;
    developers: Locator;
    soundCloudStore: Locator;
    support: Locator;
    keyboardShortcuts: Locator;
    subscription: Locator;
    settings: Locator;
    signOut: Locator;

    constructor(navbar: Locator) {
        this.dropdownContainer = navbar.getByTestId('more_dropdown');

        // Use text-based locators because these entries can render as links or buttons.
        this.aboutUs = this.dropdownContainer.getByRole('button', { name: 'About us' });
        this.legal = this.dropdownContainer.getByRole('button', { name: 'Legal' });
        this.copyright = this.dropdownContainer.getByRole('button', { name: 'Copyright' });
        this.mobileApps = this.dropdownContainer.getByRole('button', { name: 'Mobile apps' });
        this.artistMembership = this.dropdownContainer.getByRole('button', { name: 'Artist Membership' });
        this.newsroom = this.dropdownContainer.getByRole('button', { name: 'Newsroom' });
        this.jobs = this.dropdownContainer.getByRole('button', { name: 'Jobs' });
        this.developers = this.dropdownContainer.getByRole('button', { name: 'Developers' });
        this.soundCloudStore = this.dropdownContainer.getByRole('button', { name: 'SoundCloud Store' });
        this.support = this.dropdownContainer.getByRole('button', { name: 'Support' });
        this.keyboardShortcuts = this.dropdownContainer.getByRole('button', { name: 'Keyboard shortcuts' });
        this.subscription = this.dropdownContainer.getByRole('button', { name: 'Subscription' });
        this.settings = this.dropdownContainer.getByRole('button', { name: 'Settings' });
        this.signOut = this.dropdownContainer.getByRole('button', { name: 'Sign out' });
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
