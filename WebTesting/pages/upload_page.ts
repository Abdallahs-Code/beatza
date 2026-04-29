import { Page, Locator } from '@playwright/test';

export class UploadPage {
    page: Page;

    artistProBanner: Locator;
    uploadHeading: Locator;
    uploadInstructions: Locator;
    uploadDropzone: Locator;
    uploadDropzonePrompt: Locator;
    chooseFilesButton: Locator;

    artworkPanel: Locator;
    artworkPlaceholder: Locator;
    selectedTrackBar: Locator;
    selectedTrackName: Locator;
    replaceTrackButton: Locator;
    closeTrackButton: Locator;

    trackTitleInput: Locator;
    trackLinkInput: Locator;
    mainArtistsInput: Locator;
    genreSelect: Locator;
    tagsInput: Locator;
    descriptionInput: Locator;

    visibilitySection: Locator;
    publicOption: Locator;
    privateOption: Locator;
    followerExclusiveOption: Locator;
    schedulePublicReleaseOption: Locator;

    permissionsSection: Locator;
    enableDirectDownloadsSwitch: Locator;
    offlineListeningSwitch: Locator;
    includeInRssFeedSwitch: Locator;
    displayEmbedCodeSwitch: Locator;
    enableAppPlaybackSwitch: Locator;
    allowCommentsSwitch: Locator;
    showTrackCommentsToPublicSwitch: Locator;
    showTrackInsightsToPublicSwitch: Locator;

    geoblockingWorldwideOption: Locator;
    geoblockingExclusiveOption: Locator;
    geoblockingBlockedOption: Locator;

    uploadFooterNote: Locator;
    uploadButton: Locator;

    advancedToggle: Locator;
    buyLinkInput: Locator;
    recordLabelInput: Locator;
    releaseDateInput: Locator;
    releaseCalendarToggle: Locator;
    publisherInput: Locator;
    isrcInput: Locator;
    explicitContentCheckbox: Locator;
    pLineInput: Locator;

    licensingToggle: Locator;
    licensingAllRightsOption: Locator;
    licensingCreativeCommonsOption: Locator;

    constructor(page: Page) {
        this.page = page;

        this.artistProBanner = page.getByTestId('');
        this.chooseFilesButton = page.getByTestId('upload-choose-files');

        this.artworkPlaceholder = page.getByTestId('upload-artwork-add');
        this.replaceTrackButton = page.getByTestId('upload-header-replace-track');
        this.closeTrackButton = page.getByTestId('upload-header-quit');

        this.trackTitleInput = page.getByTestId('upload-track-title');
        this.trackLinkInput = page.getByTestId('upload-track-link');
        this.mainArtistsInput = page.getByTestId('upload-track-artist');
        this.genreSelect = page.getByTestId('upload-track-genre');
        this.tagsInput = page.getByTestId('upload-track-tags');
        this.descriptionInput = page.getByTestId('upload-track-description');

        this.visibilitySection = page.getByTestId('upload-track-privacy-toggle');
        this.publicOption = page.getByTestId('upload-track-privacy-public');
        this.privateOption = page.getByTestId('upload-track-privacy-private');
        this.followerExclusiveOption = page.getByTestId('upload-track-privacy-followerExclusive');
        this.schedulePublicReleaseOption = page.getByTestId('upload-track-schedule-release');

        this.permissionsSection = page.getByTestId('upload-permissions-toggle');
        this.enableDirectDownloadsSwitch = page.getByTestId('upload-permissions-enable-direct-downloads');
        this.offlineListeningSwitch = page.getByTestId('upload-permissions-offline-listening');
        this.includeInRssFeedSwitch = page.getByTestId('upload-permissions-include-in-rss-feed');
        this.displayEmbedCodeSwitch = page.getByTestId('upload-permissions-display-embed-code');
        this.enableAppPlaybackSwitch = page.getByTestId('upload-permissions-enable-app-playback');
        this.allowCommentsSwitch = page.getByTestId('upload-permissions-allow-people-to-comment-on-your-track');
        this.showTrackCommentsToPublicSwitch = page.getByTestId('upload-permissions-show-track-comments-to-public');
        this.showTrackInsightsToPublicSwitch = page.getByTestId('upload-permissions-show-track-insights-to-public');

        this.geoblockingWorldwideOption = page.getByTestId('upload-geoblocking-worldwide');
        this.geoblockingExclusiveOption = page.getByTestId('upload-geoblocking-exclusive');
        this.geoblockingBlockedOption = page.getByTestId('upload-geoblocking-blocked');


        this.advancedToggle = page.getByTestId('upload-advanced-toggle');
        this.buyLinkInput = page.getByTestId('upload-advanced-buy-link');
        this.recordLabelInput = page.getByTestId('upload-advanced-record-label');
        this.releaseDateInput = page.getByTestId('upload-advanced-release-date');
        this.releaseCalendarToggle = page.getByTestId('upload-advanced-release-calendar-toggle');
        this.publisherInput = page.getByTestId('upload-advanced-publisher');
        this.isrcInput = page.getByTestId('upload-advanced-isrc');
        this.explicitContentCheckbox = page.getByTestId('Pretty-checkbox-button');
        this.pLineInput = page.getByTestId('upload-advanced-p-line');

        this.licensingToggle = page.getByTestId('upload-licensing-toggle');
        this.licensingAllRightsOption = page.getByTestId('upload-licensing-all-rights');
        this.licensingCreativeCommonsOption = page.getByTestId('upload-licensing-creative-commons');

        this.uploadButton = page.getByTestId('upload-submit');
    }

    async openFilePicker() {
        await this.chooseFilesButton.click();
    }

    async replaceTrack() {
        await this.replaceTrackButton.click();
    }

    async closeTrackPreview() {
        await this.closeTrackButton.click();
    }

    async fillTrackDetails(trackTitle: string, trackLink: string, mainArtists: string, tags: string, description: string) {
        await this.trackTitleInput.fill(trackTitle);
        await this.trackLinkInput.fill(trackLink);
        await this.mainArtistsInput.fill(mainArtists);
        await this.tagsInput.fill(tags);
        await this.descriptionInput.fill(description);
    }

    private getGenreOptionByName(genre: string) {
        const genreSlug = genre.toLowerCase().trim().replace(/\s+/g, '-');
        return this.page.getByTestId(`upload-track-genre-${genreSlug}`);
    }

    async chooseGenre(genre: string) {
        await this.genreSelect.click();
        await this.genreSelect.fill('');
        await this.genreSelect.fill(genre);

        const genreOption = this.getGenreOptionByName(genre);
        await genreOption.click();
    }

    async setTrackPrivacy(state: 'Public' | 'Private' | 'FollowerExclusive') {
        // 1. Open the dropdown menu
        await this.visibilitySection.click();

        // 2. Select the desired option based on the argument
        switch (state) {
            case 'Public':
                await this.publicOption.click();
                break;
            case 'Private':
                await this.privateOption.click();
                break;
            case 'FollowerExclusive':
                await this.followerExclusiveOption.click();
                break;
            default:
                throw new Error(`Invalid privacy state provided: ${state}`);
        }
    }

    async setScheduledRelease() {
        await this.schedulePublicReleaseOption.click();
    }

    async openAdvancedSection() {
        await this.advancedToggle.click();
    }

    async fillAdvancedDetails(
        buyLink: string,
        recordLabel: string,
        releaseDate: string,
        publisher: string,
        isrc: string,
        pLine: string
    ) {
        await this.buyLinkInput.fill(buyLink);
        await this.recordLabelInput.fill(recordLabel);
        await this.releaseDateInput.fill(releaseDate);
        await this.publisherInput.fill(publisher);
        await this.isrcInput.fill(isrc);
        await this.pLineInput.fill(pLine);
    }

    async toggleExplicitContent() {
        await this.explicitContentCheckbox.click();
    }

    async openPermissionsSection() {
        await this.permissionsSection.click();
    }

    async setWorldwideGeoblocking() {
        await this.geoblockingWorldwideOption.click();
    }

    async setExclusiveGeoblocking() {
        await this.geoblockingExclusiveOption.click();
    }

    async setBlockedGeoblocking() {
        await this.geoblockingBlockedOption.click();
    }

    async openLicensingSection() {
        await this.licensingToggle.click();
    }

    async setAllRightsReserved() {
        await this.licensingAllRightsOption.click();
    }

    async setCreativeCommons() {
        await this.licensingCreativeCommonsOption.click();
    }

    async uploadTrack() {
        await this.uploadButton.click();
    }
}