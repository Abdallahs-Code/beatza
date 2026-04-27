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
    schedulePublicReleaseOption: Locator;

    uploadFooterNote: Locator;
    uploadButton: Locator;

    constructor(page: Page) {
        this.page = page;

        this.artistProBanner = page.getByTestId('');
        this.uploadHeading = page.getByTestId('');
        this.uploadInstructions = page.getByTestId('');
        this.uploadDropzone = page.getByTestId('');
        this.uploadDropzonePrompt = page.getByTestId('');
        this.chooseFilesButton = page.getByTestId('');

        this.artworkPanel = page.getByTestId('');
        this.artworkPlaceholder = page.getByTestId('');
        this.selectedTrackBar = page.getByTestId('');
        this.selectedTrackName = page.getByTestId('');
        this.replaceTrackButton = page.getByTestId('');
        this.closeTrackButton = page.getByTestId('');

        this.trackTitleInput = page.getByTestId('');
        this.trackLinkInput = page.getByTestId('');
        this.mainArtistsInput = page.getByTestId('');
        this.genreSelect = page.getByTestId('');
        this.tagsInput = page.getByTestId('');
        this.descriptionInput = page.getByTestId('');

        this.visibilitySection = page.getByTestId('');
        this.publicOption = page.getByTestId('');
        this.schedulePublicReleaseOption = page.getByTestId('');

        this.uploadFooterNote = page.getByTestId('');
        this.uploadButton = page.getByTestId('');
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

    async chooseGenre(genre: string) {
        await this.genreSelect.fill(genre);
    }

    async setPublicVisibility() {
        await this.publicOption.click();
    }

    async setScheduledRelease() {
        await this.schedulePublicReleaseOption.click();
    }

    async uploadTrack() {
        await this.uploadButton.click();
    }
}