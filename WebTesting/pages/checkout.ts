import { Page, Locator } from '@playwright/test';

export class CheckoutPage {
    page: Page;


    billingCycleSection: Locator;
    yearlyBillingOption: Locator;
    monthlyBillingOption: Locator;

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

    constructor(page: Page) {
        this.page = page;

        this.yearlyBillingOption = page.getByTestId('');
        this.monthlyBillingOption = page.getByTestId('');

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
    }
}