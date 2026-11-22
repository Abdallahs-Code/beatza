import { Page, Locator, expect } from '@playwright/test';
export class ProfileEditForm {
    page: Page
    form: Locator
    displayNameInput: Locator
    profileUrlInput: Locator
    firstNameInput: Locator
    lastNameInput: Locator
    cityInput: Locator
    countrySelect: Locator
    bioInput: Locator
    addlinkBtn: Locator
    supportLinkName: Locator
    addSupportLinkBtn: Locator
    cancelBtn: Locator
    saveChangesBtn: Locator
    supportLinkInput: Locator
    linkInput: Locator
    RemoveLinkBtn: Locator
    RemoveSupportLinkBtn: Locator


    constructor(page: Page) {
        this.page = page;
        const profilePage = page;
        this.form = page.getByText('Edit your Profile', { exact: true }).locator('..');
        this.displayNameInput = profilePage.getByTestId("DisplayName-input")
        this.profileUrlInput = profilePage.getByTestId("ProfileLink-input")
        this.firstNameInput = profilePage.getByTestId("FirstName-input")
        this.lastNameInput = profilePage.getByTestId("LastName-input")
        this.cityInput = profilePage.getByTestId("City-input")
        this.countrySelect = profilePage.getByTestId("Country-input-dropdown")
        this.bioInput = profilePage.getByPlaceholder('Tell the world a little bit about yourself')
        this.addlinkBtn = profilePage.getByRole("button", { name: "Add link" })
        this.addSupportLinkBtn = profilePage.getByRole("button", { name: "Add support link" })
        this.cancelBtn = profilePage.getByRole("button", { name: "Cancel" })
        this.saveChangesBtn = profilePage.getByRole("button", { name: "Save changes" })
        this.supportLinkInput = profilePage.getByTestId("SupportLink-input")
        this.supportLinkName = profilePage.getByTestId("supportLinkShortTitle")
        this.linkInput = profilePage.getByTestId("Link-input")
        this.RemoveLinkBtn = profilePage.getByTestId("RemoveLink-button-EditForm")
        this.RemoveSupportLinkBtn = profilePage.getByTestId("Remove-button-EditForm")
    }
    async fillBasicInfo(displayName: string, firstName: string, lastName: string, bio: string) {
        await this.displayNameInput.fill(displayName);
        await this.firstNameInput.fill(firstName);
        await this.lastNameInput.fill(lastName);
        await this.bioInput.fill(bio);
    }
    async setLocation(city: string, country: string) {
        await this.cityInput.fill(city);
        await this.countrySelect.click();
        await this.page.locator(`div.ant-select-item-option[title="${country}"]`).click();
    }
    async addNewLink(url: string) {
        await this.addlinkBtn.click();
        await this.linkInput.last().fill(url);
    }
    async addNewsupportLink(url: string) {
        await this.addSupportLinkBtn.click();
        await this.supportLinkInput.fill(url);
    }
    async removeLinks() {
        while ((await this.RemoveLinkBtn.count()) > 0) {
            await this.RemoveLinkBtn.first().click();
        }
        await this.RemoveSupportLinkBtn.click()
    }
}