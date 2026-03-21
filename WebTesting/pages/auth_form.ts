import { Page, Locator, expect } from '@playwright/test';
import { randomInt } from 'crypto';

export type GenderOption = 'Male' | 'Female';
export type AuthStep = 'email' | 'password' | 'details' | "passRest";
export type Months =
    | 'January'
    | 'February'
    | 'March'
    | 'April'
    | 'May'
    | 'June'
    | 'July'
    | 'August'
    | 'September'
    | 'October'
    | 'November'
    | 'December';

export class AuthForm {
    initialForm: Locator;
    detailsForm: Locator;
    forgetPasswordForm: Locator;
    googleAuthBtn: Locator;

    emailTxtBox: Locator;
    emailNotVerifiedBtn: Locator;

    passwordTxtBox: Locator;
    forgetPasswordLink: Locator;
    sendResetLink: Locator;
    emailPassResetTxtbox: Locator;


    displayNameTxtbox: Locator;
    dayDateOfBirthDrop: Locator;
    monthDateOfBirthDrop: Locator;
    yearDateOfBirthDrop: Locator;
    genderDrop: Locator;


    emailContinueBtn: Locator;
    passwordContinueBtn: Locator;
    detailsContinueBtn: Locator;

    emailBackBtn: Locator;
    detailsBackBtn: Locator;
    passwordBackBtn: Locator;
    passwordResetBackBtn: Locator;

    exitBtn: Locator;

    constructor(page: Page) {
        this.initialForm = page.getByTestId("Login-Form");
        this.detailsForm = page.getByTestId("Register-Details-Form");
        this.forgetPasswordForm = page.getByTestId("Forget-Password-Form");

        this.googleAuthBtn = this.initialForm.getByRole("button", { name: "Continue with Google" });

        this.emailTxtBox = this.initialForm.getByTestId("email-input");
        this.emailContinueBtn = this.initialForm.getByTestId("continue-button-login");
        this.emailNotVerifiedBtn = this.initialForm.getByRole("button", { name: "Send a Verification Email" });

        this.passwordTxtBox = this.initialForm.getByTestId("password-input");
        this.forgetPasswordLink = this.initialForm.getByTestId("forgot-password-button");
        this.passwordContinueBtn = this.initialForm.getByTestId("continue-button-login");

        this.displayNameTxtbox = this.detailsForm.getByTestId("DisplayName-input");
        this.monthDateOfBirthDrop = this.detailsForm.locator('select').filter({ hasText: 'Month' });
        this.dayDateOfBirthDrop = this.detailsForm.locator('select').filter({ hasText: 'Day' });
        this.yearDateOfBirthDrop = this.detailsForm.locator('select').filter({ hasText: 'Year' });

        this.genderDrop = this.detailsForm.locator('select').filter({ hasText: 'Gender (required)' });
        this.detailsContinueBtn = this.detailsForm.getByTestId("continue-button-details");


        this.detailsBackBtn = this.detailsForm.getByTestId("back-to-login-button-details");
        this.passwordBackBtn = this.initialForm.getByTestId("back-to-login-button-login");
        this.emailBackBtn = this.initialForm.getByTestId("back-to-login-button-login");
        this.passwordResetBackBtn = this.forgetPasswordForm.getByTestId("back-to-login-forgot");

        //forgetpass
        this.sendResetLink = this.forgetPasswordForm.getByTestId("send-link-button")
        this.emailPassResetTxtbox = this.initialForm.getByTestId("forget-password-email-input")


        this.exitBtn = this.initialForm.getByTestId("close-button");
    }

    async FillEmail(email: string) {
        await this.emailTxtBox.pressSequentially(email, { delay: 150 })
    }

    async FillPassword(pass: string) {
        await this.passwordTxtBox.pressSequentially(pass, { delay: 150 })
    }

    async FillDate(month: Months, day: number, year: number) {
        await this.monthDateOfBirthDrop.selectOption(`${month}`);
        await this.dayDateOfBirthDrop.selectOption(`${day}`);
        await this.yearDateOfBirthDrop.selectOption(`${year}`);
    }
    async FillGender(gender: GenderOption) {
        await this.genderDrop.selectOption(gender);
    }

    async ClickBackBtn(authStep: AuthStep) {
        const backButtons: Record<AuthStep, Locator> = {
            'email': this.emailBackBtn,
            'password': this.passwordBackBtn,
            "passRest": this.passwordResetBackBtn,
            'details': this.detailsContinueBtn
        };
        await backButtons[authStep].click();
    }

    async ClickNextBtn(authStep: AuthStep) {
        const nextButtons: Record<AuthStep, Locator> = {
            'email': this.emailContinueBtn,
            'password': this.passwordContinueBtn,
            'details': this.detailsContinueBtn,
            'passRest': this.passwordResetBackBtn
        };
        await nextButtons[authStep].click();
    }
    async ClickContinueWithGoogle() {
        await this.googleAuthBtn.click()
    }
    async ClickForgetPass() {
        await this.forgetPasswordLink.click()
    }
    async ClickSendResetLink() {
        await this.sendResetLink.click()
    }
    async ClickEmailNotVerifiedBtn() {
        await this.emailNotVerifiedBtn.click()
    }
    async Login(EmailTest: string, password: string) {
        await this.FillEmail(EmailTest)
        await this.ClickNextBtn("email")
        await this.FillPassword(password)
        await this.ClickNextBtn("password")
    }
    async Signup(EmailTest: string) {
        await this.FillEmail(EmailTest)
        await this.ClickNextBtn("email")
        await this.FillPassword("Beatza@123")
        await this.ClickNextBtn("password")

        await this.FillDate("February", 5, 2005);
        const randomNum = randomInt(2)
        if (randomNum % 2 == 0) {
            await this.FillGender("Female")
        } else {
            await this.FillGender("Male")
        }
        await this.ClickNextBtn("details")
    }
    async ForgetPass(EmailTest: string) {
        await this.FillEmail(EmailTest)
        await this.ClickNextBtn("email")
        await this.ClickForgetPass()
        await this.ClickSendResetLink()
    }

}