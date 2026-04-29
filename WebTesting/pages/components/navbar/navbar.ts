import { Page, Locator, expect } from '@playwright/test';
import { MoreDropdown } from './more_dropdown';
import { ProfileDropdown } from './profile_dropdown';

export class Navbar {
    page: Page;
    soundcloud: Locator;
    home: Locator;
    feed: Locator;
    library: Locator;
    searchBox: Locator;
    searchBtn: Locator;

    //not signed in
    signIn: Locator;
    createAccount: Locator;

    //signed in
    tryArtistProLink: Locator;
    artistStudio: Locator;

    upload: Locator;
    more_btn: Locator;
    profileBtn: Locator;
    nofications: Locator;
    messages: Locator;
    moreDropdown: MoreDropdown;
    profileDropdown: ProfileDropdown;

    constructor(page: Page) {
        this.page = page
        const navbar = page.getByTestId('Navbar')

        this.soundcloud = navbar.getByTestId("navbar_logo")

        this.home = navbar.getByRole("link", { name: "Home" })
        this.feed = navbar.getByRole("link", { name: "Feed" })
        this.library = navbar.getByRole("link", { name: "Library" })

        this.searchBox = navbar.getByRole("textbox", { name: "Search" })
        this.searchBtn = navbar.locator("#search")

        this.signIn = navbar.getByRole("button", { name: "Sign in" })
        this.createAccount = navbar.getByRole("button", { name: "Create account" })
        this.upload = navbar.getByRole("link", { name: "Upload" })

        this.tryArtistProLink = navbar.getByRole("link", { name: "Try Artist Pro" })

        this.artistStudio = navbar.getByTestId("for_artists")

        this.more_btn = navbar.getByTestId("more_button")

        this.profileBtn = navbar.getByTestId("profile_button")


        this.nofications = navbar.getByTestId("notifications")
        this.messages = navbar.getByTestId("messages")

        this.more_btn = navbar.getByTestId("more_button")
        this.moreDropdown = new MoreDropdown(page)
        this.profileDropdown = new ProfileDropdown(page)

    }

    async ClickSignIn() {
        await this.signIn.click()
    }
    async ClickCreateAccount() {
        await this.createAccount.click()
    }

    async ClickMore() {
        await this.more_btn.click()
    }
    async ClickProfile() {
        await this.profileBtn.click()
    }
    async GoToProfilePage() {
        await this.profileBtn.click()
        await this.profileDropdown.profile.click()
    }
    async GoToSubscription() {
        await this.ClickMore()
        await this.moreDropdown.subscription.click()
    }

}