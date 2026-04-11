import { Page, Locator, expect } from '@playwright/test';
export class ProfilePage {
    profileImg: Locator
    uploadheaderImg: Locator
    editBtn: Locator
    shareBtn: Locator
    uploadProfileImgBtn: Locator
    replaceImgBtn: Locator
    deleteImgBtn: Locator
    uploadSongBtn: Locator
    allLink: Locator
    popularTracksLink: Locator
    albumsLink: Locator
    playlistsLink: Locator
    repostsLink: Locator

    constructor(page: Page) {
        const profilePage = page;
        this.profileImg = profilePage.getByTestId("")
        this.uploadProfileImgBtn = profilePage.getByRole("button", { name: "Upload image" })
        this.uploadheaderImg = profilePage.getByRole("button", { name: "Upload header image" })
        this.replaceImgBtn = profilePage.getByRole("button", { name: "Replace image" })
        this.deleteImgBtn = profilePage.getByRole("button", { name: "Delete image" })

        this.editBtn = profilePage.getByTestId("")
        this.shareBtn = profilePage.getByTestId("")
        this.uploadSongBtn = profilePage.getByRole("button", { name: "Upload now" })

        this.allLink = profilePage.getByTestId("")
        this.popularTracksLink = profilePage.getByTestId("")
        this.albumsLink = profilePage.getByTestId("")
        this.playlistsLink = profilePage.getByTestId("")
        this.repostsLink = profilePage.getByTestId("")

    }
    async UploadProfileImg() {
        await this.uploadProfileImgBtn.click()
        await this.replaceImgBtn.click()
    }
    async DeleteProfileImg() {
        await this.uploadProfileImgBtn.click()
        await this.deleteImgBtn.click()
    }
    async UploadCoverImg() {
        await this.uploadheaderImg.click()
        await this.replaceImgBtn.click()
    }
    async DeleteCoverImg() {
        await this.uploadheaderImg.click()
        await this.deleteImgBtn.click()
    }
    async UploadSong() {

    }
}