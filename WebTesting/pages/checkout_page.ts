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

        this.checkoutTitle = page.getByTestId('');
        this.billingCycleSection = page.getByTestId('');
        this.yearlyBillingOption = page.getByTestId('');
        this.monthlyBillingOption = page.getByTestId('');

        this.paymentDetailsSection = page.getByTestId('');

        this.firstNameInput = page.getByTestId('');
        this.surnameInput = page.getByTestId('');
        this.cardNumberInput = page.getByTestId('');
        this.expirationDateInput = page.getByTestId('');
        this.cvvInput = page.getByTestId('');
        this.billingCountrySelect = page.getByTestId('');
        this.postcodeInput = page.getByTestId('');
        this.addBillingAddressCheckbox = page.getByTestId('');
        this.fullNameInput = page.getByTestId('');
        this.companyInput = page.getByTestId('');
        this.streetAddressInput = page.getByTestId('');
        this.cityInput = page.getByTestId('');

        this.couponCodeLink = page.getByTestId('');
        this.totalAmount = page.getByTestId('');
        this.billingCycleSummary = page.getByTestId('');
        this.buySubscriptionButton = page.getByTestId('');

        this.paymentSuccessHeading = page.getByTestId('');
        this.paymentSuccessMessage = page.getByTestId('');
        this.receiptCard = page.getByTestId('');
        this.receiptStatus = page.getByTestId('');
        this.receiptTitle = page.getByTestId('');
        this.receiptNumber = page.getByTestId('');
        this.receiptDateValue = page.getByTestId('');
        this.receiptPlanValue = page.getByTestId('');
        this.receiptBillingCycleValue = page.getByTestId('');
        this.receiptPerMonthValue = page.getByTestId('');
        this.receiptTotalPaidValue = page.getByTestId('');
        this.downloadReceiptButton = page.getByTestId('');
        this.goToHomeButton = page.getByTestId('');
    }
}