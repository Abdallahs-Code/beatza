import { Page, Locator, expect } from '@playwright/test';

export class ResetPassPage {
    passInput: Locator;
    passInputConfirm: Locator;
    passSaveBtn: Locator;
    signOutEveryWhere: Locator;

    constructor(page: Page) {
        this.passInput = page.getByTestId("reset-password-email-input")
        this.passInputConfirm = page.getByTestId("reset-password-password-input")
        this.signOutEveryWhere = page.getByTestId("sign-out-everywhere-input")
        this.passSaveBtn = page.getByRole("button", { name: "Save" })
    }
    async FillPass(password: string) {
        await this.passInput.fill(password)
        await this.passInputConfirm.fill(password)
    }
    async ClickSave() {
        await this.passSaveBtn.click()
    }
    async SetSignOut(checked: boolean) {
        await this.signOutEveryWhere.setChecked(checked)
    }
    async ResetPass(password: string, signout: boolean) {
        await this.FillPass(password)
        await this.SetSignOut(signout)
        await this.ClickSave()
    }

}