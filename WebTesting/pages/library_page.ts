import { Page, Locator, expect } from '@playwright/test';
export class LibraryPage {

    overviewLink: Locator
    likesLink: Locator
    playlistsLink: Locator
    albumsLink: Locator
    stationsLink: Locator
    followingLink: Locator
    HistoryLink: Locator

    constructor(page: Page) {
        const profilePage = page;

        this.overviewLink = profilePage.getByTestId("")
        this.likesLink = profilePage.getByTestId("")
        this.playlistsLink = profilePage.getByTestId("")
        this.albumsLink = profilePage.getByTestId("")
        this.stationsLink = profilePage.getByTestId("")
        this.followingLink = profilePage.getByTestId("")
        this.HistoryLink = profilePage.getByTestId("")

    }
}