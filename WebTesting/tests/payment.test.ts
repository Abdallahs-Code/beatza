import * as path from 'path';
import { test, expect, type Page } from '@playwright/test';
import { Navbar } from '../pages/components/navbar/navbar';
import { SubscriptionsPage } from '../pages/subscription_page';
import { CheckoutPage } from '../pages/checkout_page';

const artist1State = path.join(process.cwd(), 'playwright/.auth/artist3.json');

type CardCase = {
    name: string;
    number: string;
    exp: string;
    cvc: string;
    expectSuccess: boolean;
    expectedOutput: RegExp;
};

const cardCases: CardCase[] = [
    {
        name: 'happy path - valid Visa card',
        number: '4242424242424242',
        exp: '12/34',
        cvc: '123',
        expectSuccess: true,
        expectedOutput: /payment successful|thank you|receipt|transaction/i,
    },
    {
        name: 'declined card',
        number: '4000000000000002',
        exp: '12/34',
        cvc: '123',
        expectSuccess: false,
        expectedOutput: /declined|card was declined|unable to authenticate/i,
    },
    {
        name: 'insufficient funds',
        number: '4000000000009995',
        exp: '12/34',
        cvc: '123',
        expectSuccess: false,
        expectedOutput: /insufficient funds|not enough funds|declined/i,
    },
    {
        name: 'expired card',
        number: '4000000000000069',
        exp: '12/34',
        cvc: '123',
        expectSuccess: false,
        expectedOutput: /expired|expiration|card has expired/i,
    },
    {
        name: 'incorrect cvc',
        number: '4000000000000127',
        exp: '12/34',
        cvc: '123',
        expectSuccess: false,
        expectedOutput: /incorrect cvc|cvc is incorrect|security code/i,
    },
];

test.use({ storageState: artist1State });

test.describe.serial('Payment cards matrix', () => {
    test.setTimeout(120000);

    async function goToCheckout(page: Page) {
        await page.goto('https://beatza.me/home');
        const navbar = new Navbar(page);
        await navbar.GoToSubscription();

        const subscriptionsPage = new SubscriptionsPage(page);
        await expect(subscriptionsPage.pageTitle).toBeVisible();
        await subscriptionsPage.upgradeToArtistPro();
    }

    async function cancelIfPro(page: Page) {
        await page.goto('https://beatza.me/home');
        const navbar = new Navbar(page);
        await navbar.GoToSubscription();

        const subscriptionsPage = new SubscriptionsPage(page);
        await expect(subscriptionsPage.pageTitle).toBeVisible();

        await subscriptionsPage.cancelPlanFromModal(false);

        await expect(subscriptionsPage.tryArtistProBtn).toBeVisible({ timeout: 15000 });

    }

    for (const card of cardCases) {
        test(`pay with ${card.name}`, async ({ page }) => {
            let paymentSucceeded = false;
            try {
                await goToCheckout(page);
                const checkoutPage = new CheckoutPage(page);
                await checkoutPage.fillBillingNames('Test', 'User');
                await checkoutPage.fillPostCode('10001');
                await checkoutPage.fillCardDetails(card.number, card.exp, card.cvc);
                await checkoutPage.submitPayment();

                if (card.expectSuccess) {
                    await expect(checkoutPage.outputLocator(card.expectedOutput)).toBeVisible({ timeout: 20000 });
                    paymentSucceeded = true;
                } else {
                    await expect(checkoutPage.outputLocator(card.expectedOutput)).toBeVisible({ timeout: 20000 });
                }
            } finally {
                if (paymentSucceeded) {
                    await cancelIfPro(page);
                }
            }
        });
    }
});
