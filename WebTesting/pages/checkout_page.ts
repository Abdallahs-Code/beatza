import { Page, Locator } from '@playwright/test';

export class CheckoutPage {
    page: Page;

    checkoutTitle: Locator;

    billingCycleSection: Locator;
    yearlyBillingOption: Locator;
    monthlyBillingOption: Locator;

    paymentDetailsSection: Locator;

    firstNameInput: Locator;
    surnameInput: Locator;
    cardNumberInput: Locator;
    expirationDateInput: Locator;
    cvvInput: Locator;
    billingCountrySelect: Locator;
    postcodeInput: Locator;
    addBillingAddressCheckbox: Locator;
    fullNameInput: Locator;
    companyInput: Locator;
    streetAddressInput: Locator;
    cityInput: Locator;

    couponCodeLink: Locator;
    totalAmount: Locator;
    billingCycleSummary: Locator;
    buySubscriptionButton: Locator;

    paymentSuccessHeading: Locator;
    paymentSuccessMessage: Locator;
    receiptCard: Locator;
    receiptStatus: Locator;
    receiptTitle: Locator;
    receiptNumber: Locator;
    receiptDateValue: Locator;
    receiptPlanValue: Locator;
    receiptBillingCycleValue: Locator;
    receiptPerMonthValue: Locator;
    receiptTotalPaidValue: Locator;
    downloadReceiptButton: Locator;
    goToHomeButton: Locator;

    constructor(page: Page) {
        this.page = page;

        this.checkoutTitle = page.getByRole('heading', { name: /checkout|payment/i }).first();
        this.billingCycleSection = page.locator('section,div').filter({ hasText: /billing cycle/i }).first();
        this.yearlyBillingOption = page.getByText(/yearly/i).first();
        this.monthlyBillingOption = page.getByText(/monthly/i).first();

        this.paymentDetailsSection = page.locator('section,div').filter({ hasText: /payment details|card details/i }).first();

        this.firstNameInput = page.locator('div.relative:has(label:has-text("First name")) input').first();
        this.surnameInput = page.locator('div.relative:has(label:has-text("Surname")) input').first();
        this.cardNumberInput = page.locator('iframe[title="Secure card number input frame"]').first();
        this.expirationDateInput = page.locator('iframe[title="Secure expiration date input frame"]').first();
        this.cvvInput = page.locator('iframe[title="Secure CVC input frame"]').first();
        this.billingCountrySelect = page.locator('div.relative:has(p:has-text("Billing Country")) select').first();
        this.postcodeInput = page.locator('div.relative:has(label:has-text("Postcode")) input').first();
        this.addBillingAddressCheckbox = page.getByRole('button', { name: /add billing address/i }).first();
        this.fullNameInput = page.locator('div.relative:has(label:has-text("Full name")) input').first();
        this.companyInput = page.locator('div.relative:has(label:has-text("Company")) input').first();
        this.streetAddressInput = page.locator('div.relative:has(label:has-text("Street Address")) input').first();
        this.cityInput = page.locator('div.relative:has(label:has-text("City")) input').first();

        this.couponCodeLink = page.getByRole('button', { name: /coupon/i }).first();
        this.totalAmount = page.locator('span,div,p').filter({ hasText: /total/i }).first();
        this.billingCycleSummary = page.locator('span,div,p').filter({ hasText: /monthly|yearly/i }).first();
        this.buySubscriptionButton = page.getByRole('button', { name: /buy subscription|subscribe|pay/i }).first();

        this.paymentSuccessHeading = page.getByRole('heading', { name: /payment successful|thank you/i }).first();
        this.paymentSuccessMessage = page.getByText(/payment successful|thank you|receipt|transaction/i).first();
        this.receiptCard = page.locator('div,section,article').filter({ hasText: /receipt|transaction/i }).first();
        this.receiptStatus = page.locator('span,div').filter({ hasText: /paid|payment/i }).first();
        this.receiptTitle = page.getByText(/receipt|transaction/i).first();
        this.receiptNumber = page.getByText(/#\d+|transaction/i).first();
        this.receiptDateValue = page.getByText(/date/i).first();
        this.receiptPlanValue = page.getByText(/plan/i).first();
        this.receiptBillingCycleValue = page.getByText(/billing cycle|monthly|yearly/i).first();
        this.receiptPerMonthValue = page.getByText(/per month/i).first();
        this.receiptTotalPaidValue = page.getByText(/total paid|total/i).first();
        this.downloadReceiptButton = page.getByRole('button', { name: /download receipt/i }).first();
        this.goToHomeButton = page.getByRole('button', { name: /go to home|home/i }).first();
    }

    async fillBillingNames(firstName: string, surname: string) {
        await this.firstNameInput.fill(firstName);
        await this.surnameInput.fill(surname);
    }

    async fillPostCode(postCode: string) {
        await this.postcodeInput.fill(postCode);
    }

    async fillCardDetails(number: string, exp: string, cvc: string) {
        await this.page
            .frameLocator('iframe[title="Secure card number input frame"]')
            .locator('input[name="cardnumber"]')
            .fill(number);

        await this.page
            .frameLocator('iframe[title="Secure expiration date input frame"]')
            .locator('input[name="exp-date"]')
            .fill(exp);

        await this.page
            .frameLocator('iframe[title="Secure CVC input frame"]')
            .locator('input[name="cvc"]')
            .fill(cvc);
    }

    async submitPayment() {
        await this.buySubscriptionButton.click();
    }

    outputLocator(output: RegExp): Locator {
        return this.page.getByText(output).first();
    }
}