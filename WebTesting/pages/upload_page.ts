import { Page, Locator, expect } from '@playwright/test';
export class UploadPage {
    profileImg: Locator


    constructor(page: Page) {
        const profilePage = page;
        this.profileImg = profilePage.getByTestId("")
        this.uploadProfileImgBtn = profilePage.getByRole("button", { name: "Upload image" })

    }

    async UploadCoverImg(imgPath: string) {

    }
    async UploadSong(songPath: string) {

    }
}