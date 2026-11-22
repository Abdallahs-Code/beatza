import * as path from 'path';
import { test, expect } from '@playwright/test';
import { UploadPage } from '../pages/upload_page';
import { Navbar } from '../pages/components/navbar/navbar';
import { ArtistStudioPage } from '../pages/artistStudio_page';

const listener2State = path.join(process.cwd(), 'playwright/.auth/listener2.json'); // Adjust file name if needed

test.use({ storageState: listener2State })

test.describe('Audio Track Upload Flow', () => {
    let uploadedTrackTitle: string | null = null;

    test.beforeEach(async ({ page }) => {
        // Navigate to home page
        await page.goto('https://beatza.me/home');

        // Use navbar to navigate to upload page
        const navbar = new Navbar(page);
        await navbar.upload.click();
    });

    test.afterEach(async ({ page }) => {
        if (!uploadedTrackTitle) {
            return;
        }

        // Navigate to artist studio using navbar profile dropdown
        await page.goto('https://beatza.me/home');
        const navbar = new Navbar(page);
        await navbar.artistStudio.click()

        const artistStudio = new ArtistStudioPage(page);
        await expect(artistStudio.tabBeatzaTracks).toBeVisible();

        // Filter/find the uploaded track and delete it from the row menu
        await artistStudio.searchTracksInput.fill(uploadedTrackTitle);
        const targetTrack = artistStudio.getTrackRowByTitle(uploadedTrackTitle);

        if ((await targetTrack.moreOptions.count()) > 0) {
            await targetTrack.moreOptions.first().click();

            await artistStudio.menuDeleteTrackItem.first().click();

            // Handle the delete confirmation modal (no fallback)
            await artistStudio.deleteModalCheckbox.first().check();
            await artistStudio.deleteModalDeleteButton.first().click();
        }

        uploadedTrackTitle = null;
    });

    test('should successfully upload a track and fill required metadata', async ({ page }) => {
        test.setTimeout(50000);
        const uploadPage = new UploadPage(page);
        uploadedTrackTitle = `Khodny Bein Edeik ${Date.now()}`;

        // 1. Handle the native file upload dialog
        const fileChooserPromise = page.waitForEvent('filechooser');
        await uploadPage.openFilePicker();
        const fileChooser = await fileChooserPromise;

        // Point this to a dummy audio file in your project directory
        await fileChooser.setFiles('upload assets/Hamid El Shaeri - Khodny Bein Edeik  حميد الشاعرى - خدني بين اديك.mp3');

        // 2. Wait for the form to render after the file is loaded
        await expect(uploadPage.trackTitleInput).toBeVisible();

        // 3. Fill in the primary track details using the POM method
        await uploadPage.fillTrackDetails(
            uploadedTrackTitle,               // trackTitle
            'khodny-bein-edeik',              // trackLink (the permalink suffix)
            'Hamid El Shaeri',                // mainArtists
            'Pop, 90s, Arabic',               // tags
            'Automated test upload ensuring the form processes metadata correctly.' // description
        );

        // 4. Select the genre from searchable dropdown
        await uploadPage.chooseGenre('World');

        // 5. Confirm visibility settings
        await uploadPage.setTrackPrivacy("Public");

        // 6. Submit the form
        await uploadPage.uploadTrack();
        await page.waitForURL('https://beatza.me/home', {
            timeout: 60000 // Time in milliseconds (60,000ms = 60 seconds)
        });

    });
});