import { Page, Locator, expect } from '@playwright/test';

export class ProfileDropdown {
    dropdownContainer: Locator;

    profile: Locator;
    likes: Locator;
    playlists: Locator;
    stations: Locator;
    whoToFollow: Locator;
    tryArtistPro: Locator;
    tracks: Locator;
    insights: Locator;
    distribute: Locator;

    constructor(page: Page) {
        this.dropdownContainer = page.getByTestId('profile_dropdown');
        //menu items
        this.profile = this.dropdownContainer.getByTestId("profile-item-link-btn")
        this.likes = this.dropdownContainer.getByTestId("likes-item-link-btn")
        this.playlists = this.dropdownContainer.getByTestId("playlists-item-link-btn")
        this.stations = this.dropdownContainer.getByTestId("stations-item-link-btn")
        this.tryArtistPro = this.dropdownContainer.getByTestId("following-item-link-btn")
        this.whoToFollow = this.dropdownContainer.getByTestId("who-to-follow-item-link-btn")
        this.tracks = this.dropdownContainer.getByTestId("tracks-item-link-btn")
        this.insights = this.dropdownContainer.getByTestId("insights-item-link-btn")
    }

}