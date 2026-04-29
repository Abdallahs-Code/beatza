import { Page, Locator } from '@playwright/test';

export class ArtistStudioPage {
    readonly page: Page;

    // Top Navigation Bar (Not in HTML snippet, leaving as placeholders)
    readonly topNavSearchInput: Locator;
    readonly topNavUploadButton: Locator;
    readonly topNavNotificationsIcon: Locator;
    readonly topNavMessagesIcon: Locator;
    readonly topNavProfileAvatar: Locator;

    // Pro Banner
    readonly artistProBanner: Locator;

    // Artist Studio Header Stats
    readonly statPlays: Locator;
    readonly statReposts: Locator;
    readonly statDownloads: Locator;
    readonly statLikes: Locator;
    readonly statComments: Locator;

    // Quick Links / Insights
    readonly linkInsights: Locator;
    readonly linkEarnings: Locator;
    readonly linkFans: Locator;
    readonly linkBenefits: Locator;

    // Main Navigation Tabs
    readonly tabBeatzaTracks: Locator;
    readonly tabDistribution: Locator;
    readonly tabVinylRecords: Locator;
    readonly tabComments: Locator;
    readonly tabPromotions: Locator;

    // Actions & Filters
    readonly uploadOrDropTracksButton: Locator;
    readonly searchTracksInput: Locator;
    readonly filterPublicButton: Locator;
    readonly filterPrivateButton: Locator;
    readonly totalTracksCount: Locator;
    readonly sortDropdown: Locator;

    // Track List Header
    readonly selectAllTracksCheckbox: Locator;

    // Individual Track Row Base & Elements
    readonly trackRowContainer: Locator;
    readonly trackRowCheckbox: Locator;
    readonly trackArtworkBtn: Locator;
    readonly trackAmplifyButton: Locator;
    readonly trackMoreOptionsButton: Locator;

    readonly menuEditItem: Locator;
    readonly menuAddToPlaylistItem: Locator;
    readonly menuCopyLinkItem: Locator;
    readonly menuDeleteTrackItem: Locator;

    // Delete Confirmation Modal
    readonly deleteModalCheckbox: Locator;
    readonly deleteModalCancelButton: Locator;
    readonly deleteModalDeleteButton: Locator;

    constructor(page: Page) {
        this.page = page;

        // Top Navigation Bar (Placeholders)
        this.topNavSearchInput = page.getByRole('searchbox');
        this.topNavUploadButton = page.getByRole('button', { name: 'Upload' });
        this.topNavNotificationsIcon = page.getByLabel('Notifications');
        this.topNavMessagesIcon = page.getByLabel('Messages');
        this.topNavProfileAvatar = page.getByAltText('Profile');

        // Pro Banner
        this.artistProBanner = page.locator('span:has-text("Artist Pro")');

        // Artist Studio Header Stats (Using text filtering for robustness)
        this.statPlays = page.locator('div').filter({ hasText: /^SC plays$/ }).locator('span').first();
        this.statReposts = page.locator('div').filter({ hasText: /^Reposts$/ }).locator('span').first();
        this.statDownloads = page.locator('div').filter({ hasText: /^Downloads$/ }).locator('span').first();
        this.statLikes = page.locator('div').filter({ hasText: /^Likes$/ }).locator('span').first();
        this.statComments = page.locator('div').filter({ hasText: /^Comments$/ }).locator('span').first();

        // Quick Links / Insights
        this.linkInsights = page.locator('span.text-white-smoke', { hasText: 'Insights' });
        this.linkEarnings = page.locator('span.text-white-smoke', { hasText: 'Earnings' });
        this.linkFans = page.locator('span.text-white-smoke', { hasText: 'Fans' });
        this.linkBenefits = page.locator('span.text-white-smoke', { hasText: 'Benefits' });

        // Main Navigation Tabs (Mapped from HTML)
        this.tabBeatzaTracks = page.getByTestId('artist-tab-tracks');
        this.tabDistribution = page.getByTestId('artist-tab-distribution');
        this.tabVinylRecords = page.getByTestId('artist-tab-vinyl');
        this.tabComments = page.getByTestId('artist-tab-comments');
        this.tabPromotions = page.getByTestId('artist-tab-promotions');

        // Actions & Filters (Mapped from HTML)
        this.uploadOrDropTracksButton = page.getByTestId('artist-tracks-upload');
        this.searchTracksInput = page.getByTestId('artist-tracks-search');
        this.filterPublicButton = page.getByTestId('artist-tracks-filter-public');
        this.filterPrivateButton = page.getByTestId('artist-tracks-filter-private');

        // Count & Sort
        this.totalTracksCount = page.locator('span.font-semibold:has-text("tracks")');
        this.sortDropdown = page.getByTestId('artist-tracks-sort-toggle');

        // Track List Area
        // The HTML provides a specific checkbox testid
        this.selectAllTracksCheckbox = page.getByTestId('Pretty-checkbox-button').first();

        // Base locator for a track container row
        this.trackRowContainer = page.locator('.border-b.border-\\[\\#1e1e1e\\]');

        // Since track IDs are dynamic (e.g., 69ebeacecd350521b9b1e9c6), we use CSS starts-with selectors (^=)
        this.trackRowCheckbox = page.getByTestId('Pretty-checkbox-button');
        this.trackArtworkBtn = page.locator('[data-testid^="artist-track-row-play-"]');
        this.trackMoreOptionsButton = page.locator('[data-testid^="artist-track-row-menu-"]');
        this.trackAmplifyButton = page.locator('[data-testid^="artist-track-row-amplify-"]');

        this.selectAllTracksCheckbox = page.getByTestId('Pretty-checkbox-button').first();
        this.trackRowContainer = page.locator('.border-b.border-\\[\\#1e1e1e\\]');
        this.trackRowCheckbox = page.getByTestId('Pretty-checkbox-button');
        this.trackArtworkBtn = page.locator('[data-testid^="artist-track-row-play-"]');
        this.trackMoreOptionsButton = page.locator('[data-testid^="artist-track-row-menu-"]');
        this.trackAmplifyButton = page.locator('[data-testid^="artist-track-row-amplify-"]');

        this.menuEditItem = page.getByTestId('artist-track-menu-edit');
        this.menuAddToPlaylistItem = page.getByTestId('artist-track-menu-add-to-playlist');
        this.menuCopyLinkItem = page.getByTestId('artist-track-menu-copy-link');
        this.menuDeleteTrackItem = page.getByTestId('artist-track-menu-delete-track');

        this.deleteModalCheckbox = page.getByTestId("artist-delete-track-confirm-checkbox")
        // Look for buttons by name with exact/case-insensitivity to match visual
        this.deleteModalCancelButton = page.getByRole("button", { name: "Cancel" })
        this.deleteModalDeleteButton = page.getByRole("button", { name: "Delete track" })
    }

    /**
     * Helper method to scope locators to a specific track row based on its text content.
     * This makes it easy to target buttons inside a specific track's row.
     */
    getTrackRowByTitle(title: string) {
        const row = this.trackRowContainer.filter({ hasText: title });
        return {
            row,
            checkbox: row.locator(this.trackRowCheckbox),
            playArtworkBtn: row.locator(this.trackArtworkBtn),
            amplifyButton: row.locator(this.trackAmplifyButton),
            moreOptions: row.locator(this.trackMoreOptionsButton),
            playsCount: row.locator('span.font-semibold:has-text("plays")'),
            duration: row.locator('span:has(svg)').nth(0), // First SVG group is usually duration based on your DOM
            dateAdded: row.locator('span').filter({ hasText: /202\d/ }) // Grabs the date string
        };
    }
}