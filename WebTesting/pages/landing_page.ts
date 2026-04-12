import { Page, Locator, expect } from '@playwright/test';

export class LandingPage {
    signInBtn: Locator
    createAccountBtn: Locator
    forArtistsLink: Locator
    uploadBtn: Locator
    getStartedBtn: Locator
    searchbox: Locator
    searchBtn: Locator
    uploadYourOwnBtn: Locator
    exploreTrendingPlaylistsBtn: Locator

    constructor(page: Page) {
        this.signInBtn = page.getByRole("button", { name: "Sign in" }).first()
        this.createAccountBtn = page.getByRole("button", { name: "Create account" })
        this.forArtistsLink = page.getByRole("link", { name: "For Artists" })
        this.uploadBtn = page.getByRole("button", { name: "Upload" })
        this.getStartedBtn = page.getByRole("button", { name: "Get Started" })
        this.searchbox = page.getByTestId("search_bar")
        this.searchBtn = page.locator("#search")
        this.uploadYourOwnBtn = page.getByRole("button", { name: "Upload Your Own" })
        this.exploreTrendingPlaylistsBtn = page.getByRole("button", { name: "Explore Trending Playlists" })
    }
}