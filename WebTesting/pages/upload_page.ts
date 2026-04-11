import { Page, Locator, expect } from '@playwright/test';
export class UploadPage {
    profileImg: Locator
    headerImg: Locator
    editBtn: Locator
    shareBtn: Locator
    uploadProfileImgBtn: Locator
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
        this.headerImg = profilePage.getByTestId("")
        this.editBtn = profilePage.getByTestId("")
        this.shareBtn = profilePage.getByTestId("")
        this.uploadSongBtn = profilePage.getByRole("button", { name: "Upload now" })

        this.allLink = profilePage.getByTestId("")
        this.popularTracksLink = profilePage.getByTestId("")
        this.albumsLink = profilePage.getByTestId("")
        this.playlistsLink = profilePage.getByTestId("")
        this.repostsLink = profilePage.getByTestId("")

    }

    async UploadCoverImg(imgPath: string) {

    }
    async UploadSong(songPath: string) {

    }
}