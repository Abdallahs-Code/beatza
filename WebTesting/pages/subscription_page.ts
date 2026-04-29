import { Locator, Page } from '@playwright/test';

export class SubscriptionsPage {
    page: Page;

    // --- Headers ---
    pageTitle: Locator;
    currentPlansHeader: Locator;
    purchaseHistoryHeader: Locator;

    // --- Current Plan Section ---
    basicPlanTitle: Locator;
    artistProPlanTitle: Locator;
    planDescription: Locator;

    // Pro-specific text
    renewalText: Locator;
    billingCycleText: Locator;

    // Action Buttons
    tryArtistProBtn: Locator;
    changeSubscriptionBtn: Locator;
    cancelSubscriptionBtn: Locator;

    // Cancellation Modal
    cancelModalTitle: Locator;
    cancelConfirmCheckbox: Locator;
    keepSubscriptionBtn: Locator;
    cancelImmediatelyBtn: Locator;
    cancelAtPeriodEndBtn: Locator;

    // --- Promos ---
    studentPromoLink: Locator;
    getArtistPro: Locator;

    constructor(page: Page) {
        this.page = page;

        // Headers
        this.pageTitle = page.getByRole('heading', { name: 'Subscriptions', exact: true });
        this.currentPlansHeader = page.getByRole('heading', { name: 'Current Plans', exact: true });
        this.purchaseHistoryHeader = page.getByRole('heading', { name: 'Purchase History', exact: true });

        // Plan Titles (Looking for the bold text of the plan name)
        this.basicPlanTitle = page.getByText('Basic', { exact: true });
        this.artistProPlanTitle = page.getByText('Artist Pro', { exact: true });
        this.planDescription = page.getByText('Artist Pro plans include unlimited upload space and advanced features.');

        // Pro-specific billing info
        this.renewalText = page.getByText(/Renews automatically on/i);
        this.billingCycleText = page.getByText(/Yearly Plan|Monthly Plan/i);

        // Buttons
        this.tryArtistProBtn = page.getByRole('button', { name: 'Try Artist Pro' });
        this.changeSubscriptionBtn = page.getByRole('button', { name: 'Change Subscription' });
        this.cancelSubscriptionBtn = page.getByRole('button', { name: 'Cancel Subscription' });

        // Cancellation modal
        this.cancelModalTitle = page.getByRole('heading', { name: 'Cancel Subscription' });
        this.cancelConfirmCheckbox = page.getByRole('checkbox', { name: /i understand i will lose access/i });
        this.keepSubscriptionBtn = page.getByRole('button', { name: 'Keep Subscription' });
        this.cancelImmediatelyBtn = page.getByRole('button', { name: 'Cancel Immediately' });
        this.cancelAtPeriodEndBtn = page.getByRole('button', { name: 'Cancel at Period End' });

        // Promos
        this.studentPromoLink = page.getByRole('link', { name: 'Get BeatZa Go+ for 50% off' });
        this.getArtistPro = page.getByRole("link", { name: "Get Artist Pro" })
    }

    // ---------------------------------------------------------
    // Page Actions & State Checks
    // ---------------------------------------------------------



    /**
     * Checks if the user is currently on the Basic plan.
     */
    async isBasicPlan(): Promise<boolean> {
        return await this.tryArtistProBtn.isVisible();
    }

    /**
     * Checks if the user is currently on the Artist Pro plan.
     */
    async isArtistProPlan(): Promise<boolean> {
        return await this.cancelSubscriptionBtn.isVisible();
    }

    /**
     * Initiates the upgrade flow.
     */
    async upgradeToArtistPro() {
        await this.tryArtistProBtn.click();
        await this.getArtistPro.click()
    }

    /**
     * Initiates the cancellation flow.
     */
    async cancelPlan() {
        await this.cancelSubscriptionBtn.click();
    }

    /**
     * Cancels the current Artist Pro subscription through the confirmation modal form.
     */
    async cancelPlanFromModal(cancelAtPeriodEnd: boolean = true) {
        await this.cancelSubscriptionBtn.click();
        await this.cancelModalTitle.waitFor({ state: 'visible' });

        await this.cancelConfirmCheckbox.check();

        if (cancelAtPeriodEnd) {
            await this.cancelAtPeriodEndBtn.click();
        } else {
            await this.cancelImmediatelyBtn.click();
        }
    }

    // ---------------------------------------------------------
    // Purchase History Helpers
    // ---------------------------------------------------------

    /**
     * Retrieves a specific transaction card locator by its Transaction ID (e.g., "#10")
     * This allows you to chain assertions on a specific card.
     */
    getTransactionCard(transactionNumber: string): Locator {
        // Finds the element containing "Transaction #10" and goes up to its container card.
        // We assume the card itself has a recognizable HTML element structure, like an article or div wrapper.
        return this.page.locator('div').filter({ hasText: `Transaction ${transactionNumber}` }).first();
    }

    /**
     * Extracts the status badge text (Payment, Cancellation, subscription_created) 
     * for a specific transaction number.
     */
    async getTransactionStatus(transactionNumber: string): Promise<string | null> {
        const card = this.getTransactionCard(transactionNumber);
        // Assuming the badges have specific classes or roles. 
        // Here we find the span/div inside the card that holds the status text.
        // You may need to refine the `.badge` selector to match your CSS framework (e.g., Tailwind's `bg-red-500` etc.)
        const statusBadge = card.locator('span, div').filter({ hasText: /Payment|Cancellation|subscription_created/i }).first();
        return await statusBadge.textContent();
    }
}