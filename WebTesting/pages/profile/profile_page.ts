import { Page, Locator, expect } from '@playwright/test';
import { ProfileEditForm } from '../profile/profile_edit_form'
export class ProfilePage {
    profileImg: Locator
    headerImg: Locator
    uploadheaderImgBtn: Locator
    uploadProfileImgBtn: Locator

    editBtn: Locator
    editform: ProfileEditForm

    replaceImgBtn: Locator
    deleteImgBtn: Locator
    uploadSongBtn: Locator
    supportArtistBtn: Locator
    allLink: Locator
    popularTracksLink: Locator
    albumsLink: Locator
    playlistsLink: Locator
    repostsLink: Locator

    shareBtn: Locator
    moreBtn: Locator
    followBtn: Locator
    sendMsgBtn: Locator

    constructor(page: Page) {
        const profilePage = page;
        this.profileImg = profilePage.getByTestId("")
        this.headerImg = profilePage.getByTestId("")
        this.uploadProfileImgBtn = profilePage.getByRole("button", { name: "Upload image" })
        this.uploadheaderImgBtn = profilePage.getByRole("button", { name: "Upload header image" })
        this.replaceImgBtn = profilePage.getByRole("button", { name: "Replace image" })
        this.deleteImgBtn = profilePage.getByRole("button", { name: "Delete image" })

        this.editBtn = profilePage.getByRole("button", { name: "Edit", exact: true })
        this.editform = new ProfileEditForm(page)
        this.shareBtn = profilePage.getByRole("button", { name: "Share" })
        this.supportArtistBtn = profilePage.getByRole('button', { name: /Support/i })
        this.uploadSongBtn = profilePage.getByRole("button", { name: "Upload now" })

        this.allLink = profilePage.getByTestId("")
        this.popularTracksLink = profilePage.getByTestId("")
        this.albumsLink = profilePage.getByTestId("")
        this.playlistsLink = profilePage.getByTestId("")
        this.repostsLink = profilePage.getByTestId("")


        this.moreBtn = profilePage.getByTestId("ThreeDots-button")
        this.repostsLink = profilePage.getByTestId("")
        this.followBtn = profilePage.getByTestId("Follow-button")
        this.sendMsgBtn = profilePage.getByTestId("SendMsg-button")

    }
    async ClickEditBtn() {
        await this.editBtn.click()
    }
    async UploadProfileImg() {
        await this.uploadProfileImgBtn.click()
        await this.replaceImgBtn.click()
    }
    async DeleteProfileImg() {
        await this.uploadProfileImgBtn.click()
        await this.deleteImgBtn.click()
    }
    async UploadHeaderImg() {
        await this.uploadheaderImgBtn.click()
        await this.replaceImgBtn.click()
    }
    async DeleteCoverImg() {
        await this.uploadheaderImgBtn.click()
        await this.deleteImgBtn.click()
    }

}