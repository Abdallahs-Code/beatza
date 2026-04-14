import { Locator, Page } from '@playwright/test';

export class BlockForm {
    page: Page;
    removeCommentsCheckbox: Locator;
    reportSpamCheckbox: Locator;
    cancelBtn: Locator;
    blockBtn: Locator;

    constructor(page: Page) {
        this.page = page;
        this.removeCommentsCheckbox = page.getByRole('checkbox', { name: /Also permanently remove this user's comments/i });
        this.reportSpamCheckbox = page.getByRole('checkbox', { name: /Also report.*for spam/i });

        this.cancelBtn = page.getByRole('button', { name: 'Cancel' });

        this.blockBtn = page.getByRole('button', { name: /^Block/i }).last();
    }

    async ToggleRemoveComments(check: boolean = true) {
        const isChecked = await this.removeCommentsCheckbox.isChecked();
        if (check !== isChecked) {
            await this.removeCommentsCheckbox.click();
        }
    }

    async ToggleReportSpam(check: boolean = true) {
        const isChecked = await this.reportSpamCheckbox.isChecked();
        if (check !== isChecked) {
            await this.reportSpamCheckbox.click();
        }
    }

    async SubmitBlock() {
        await this.blockBtn.click();
    }

    async ClickCancel() {
        await this.cancelBtn.click();
    }
}
