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

    constructor(navbar: Locator) {
        this.dropdownContainer = navbar.getByTestId('profile_dropdown');
        //menu items
        this.profile = this.dropdownContainer.getByRole("button", { name: "Profile" })
        this.likes = this.dropdownContainer.getByRole("button", { name: "Likes" })
        this.playlists = this.dropdownContainer.getByRole("button", { name: "Playlists" })
        this.stations = this.dropdownContainer.getByRole("button", { name: "Stations" })
        this.tryArtistPro = this.dropdownContainer.getByRole("button", { name: "Following" })
        this.whoToFollow = this.dropdownContainer.getByRole("button", { name: "Who to follow" })
        this.tracks = this.dropdownContainer.getByRole("button", { name: "Tracks" })
        this.insights = this.dropdownContainer.getByRole("button", { name: "Insights" })
        this.distribute = this.dropdownContainer.getByRole("button", { name: "Destribute" })
    }

}