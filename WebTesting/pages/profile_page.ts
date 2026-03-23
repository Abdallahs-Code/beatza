import { Page, Locator, expect } from '@playwright/test';
export class ProfilePage {
    profileImg: Locator
    headerImg: Locator
    editBtn: Locator
    shareBtn: Locator
    uploadBtn: Locator
    allLink: Locator
    popularTracksLink: Locator
    albumsLink: Locator
    playlistsLink: Locator
    repostsLink: Locator

    constructor(page: Page) {
        const profilePage = page;
        this.profileImg = profilePage.getByTestId("")
        this.headerImg = profilePage.getByTestId("")
        this.editBtn = profilePage.getByTestId("")
        this.shareBtn = profilePage.getByTestId("")
        this.uploadBtn = profilePage.getByTestId("")

        this.allLink = profilePage.getByTestId("")
        this.popularTracksLink = profilePage.getByTestId("")
        this.albumsLink = profilePage.getByTestId("")
        this.playlistsLink = profilePage.getByTestId("")
        this.repostsLink = profilePage.getByTestId("")

    }
}