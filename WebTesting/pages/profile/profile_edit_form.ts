import { Page, Locator, expect } from '@playwright/test';
export class ProfileEditForm {
    form: Locator
    displayNameInput: Locator
    profileUrlInput: Locator
    firstNameInput: Locator
    lastNameInput: Locator
    cityInput: Locator
    countryInput: Locator
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
        const profilePage = page;
        this.form = page.getByText('Edit your Profile', { exact: true }).locator('..');
        this.displayNameInput = profilePage.getByTestId("DisplayName-input")
        this.profileUrlInput = profilePage.getByTestId("ProfileLink-input")
        this.firstNameInput = profilePage.getByTestId("FirstName-input")
        this.lastNameInput = profilePage.getByTestId("LastName-input")
        this.cityInput = profilePage.getByTestId("City-input")
        this.countryInput = profilePage.getByTestId("Country-input")
        this.bioInput = profilePage.getByPlaceholder('Tell the world a little bit about yourself')
        this.addlinkBtn = profilePage.getByTestId("AddLink-button-EditForm")
        this.addSupportLinkBtn = profilePage.getByTestId("AddSupportLink-button-EditForm")
        this.cancelBtn = profilePage.getByTestId("cancel-button-EditForm")
        this.saveChangesBtn = profilePage.getByTestId("Save-button-EditForm")
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
    async fillLocation(city: string, country: string) {
        await this.cityInput.fill(city);
        await this.countryInput.fill(country);
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