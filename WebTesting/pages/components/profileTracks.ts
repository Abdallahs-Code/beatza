import { Locator, Page } from '@playwright/test';

export class ProfileTrack {
    // We store the root element so all other locators can be scoped inside it
    root: Locator;

    // Track Identity & Metadata
    coverArt: Locator;
    playButton: Locator;
    uploaderName: Locator;
    trackTitle: Locator;

    // Playback Visuals
    waveform: Locator;
    durationLabel: Locator;

    // Action Bar Buttons
    likeButton: Locator;
    likeCount: Locator;
    repostButton: Locator;
    repostCount: Locator;
    shareButton: Locator;
    copyLinkButton: Locator;
    downloadButton: Locator;
    moreOptionsButton: Locator;

    constructor(rootLocator: Locator) {
        this.root = rootLocator;

        // Identity (You will need to adjust these selectors to match your actual DOM)
        this.coverArt = this.root.locator('[data-testid="track-artwork"]');
        this.playButton = this.root.locator('button[aria-label="Play"]');
        this.uploaderName = this.root.locator('.uploader-name'); // e.g., "Beatzatesting"
        this.trackTitle = this.root.locator('.track-title');     // e.g., "Stromae - papaoutai..."

        // Playback
        this.waveform = this.root.locator('[data-testid="waveform-container"]');
        this.durationLabel = this.root.locator('.track-duration'); // e.g., "3:53"

        // Actions Bar (Bottom Row)
        this.likeButton = this.root.locator('button[data-testid="like-btn"]');
        this.likeCount = this.likeButton.locator('.action-count'); // Assumes count is inside the button

        this.repostButton = this.root.locator('button[data-testid="repost-btn"]');
        this.repostCount = this.repostButton.locator('.action-count');

        this.shareButton = this.root.locator('button[aria-label="Share"]');
        this.copyLinkButton = this.root.locator('button[aria-label="Copy Link"]');
        this.downloadButton = this.root.locator('button[aria-label="Download"]');
        this.moreOptionsButton = this.root.locator('button[aria-label="More options"]');
    }

    // ---------------------------------------------------------
    // Reusable Component Actions
    // ---------------------------------------------------------

    async togglePlay() {
        await this.playButton.click();
    }

    async likeTrack() {
        await this.likeButton.click();
    }

    async getTrackDetails() {
        return {
            uploader: await this.uploaderName.innerText(),
            title: await this.trackTitle.innerText(),
        };
    }

