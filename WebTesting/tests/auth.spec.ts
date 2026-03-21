import path from 'path';
import { test, expect, chromium } from '@playwright/test';
import { Navbar } from '../pages/components/navbar/navbar';
import { AuthForm } from '../pages/auth_form';
import { LandingPage } from '../pages/landing_page';
import { EmailVerificationLink, EmailResetPass } from './verification'
import { ResetPassPage } from '../pages/reset_password_page';

test.describe("authentication (Happy Path)", () => {


  test("Signup with Email", async ({ page }) => {
    test.setTimeout(40000);
    await page.goto('https://beatza.me');

    const landingPage = new LandingPage(page)

    await page.waitForLoadState();

    await landingPage.signInBtn.click()

    const loginForm = new AuthForm(page)
    const testEmail = `beatzatesting+${Date.now()}@gmail.com`;
    await loginForm.Signup(testEmail)

    await page.waitForTimeout(6000)
    const verificationLink = await EmailVerificationLink(testEmail)
    await page.goto(verificationLink, { waitUntil: 'networkidle' });


    await page.goto('https://beatza.me')
    await landingPage.signInBtn.click()

    await loginForm.Login(testEmail, "Beatza@123")
    await expect(page).toHaveURL(/\/home/);



  })
  test("Login with Email and signout", async ({ page }) => {
    await page.goto('https://beatza.me');

    const landingPage = new LandingPage(page)

    await page.waitForLoadState();

    await landingPage.signInBtn.click()

    const signUpForm = new AuthForm(page)
    const testEmail = `beatzatesting+loggedin@gmail.com`;
    await signUpForm.Login(testEmail, "Beatza@123")

    await expect(page).toHaveURL(/\/home/);
    const navbar = new Navbar(page)
    await navbar.ClickMore()
    await navbar.moreDropdown.ClickSignOut()
    // await expect(page).toHaveURL("beatza.me");



  })
  // test("verification via link", async ({ page }) => {
  //   console.log(await EmailVerificationLink("beatzatesting+21774008092166@gmail.com"))

  // })
  test("Forget Password", async ({ page }) => {
    await page.goto('https://beatza.me');
    const landingPage = new LandingPage(page)

    await landingPage.signInBtn.click()

    const resetForm = new AuthForm(page)
    const testEmail = `beatzatesting+passreset@gmail.com`;
    await resetForm.ForgetPass(testEmail)
    await page.waitForTimeout(6000)
    const resetPassLink = await EmailResetPass(testEmail)

    await page.goto(resetPassLink)
    const passResetPage = new ResetPassPage(page)
    await expect(page.getByRole("heading", { level: 1, name: /change your password/i })).toBeVisible();
    const newPass = `Beatza@${Date.now()}`
    await passResetPage.ResetPass(newPass, false)

    await page.goto('https://beatza.me')
    await landingPage.signInBtn.click()

    const loginForm = new AuthForm(page)
    await loginForm.Login(testEmail, newPass)


  })

  test("Qr login", async ({ page }) => {


  })
  test("Continue with Google auth", async ({ page }) => {
    await page.goto('https://beatza.me');

    const landingPage = new LandingPage(page)

    await page.waitForLoadState();

    await landingPage.signInBtn.click()

    const loginForm = new AuthForm(page)

    await loginForm.ClickContinueWithGoogle()
    // await page.getByRole("button", { name: "Continue with Google" }).click();
    //! to be ssen if it works make pom
    await page.waitForLoadState();
    await page.getByRole("textbox", { name: "email" }).pressSequentially('aliniazi.dev@gmail.com', { delay: 150 })
    await page.waitForTimeout(1000);
    await page.getByRole("button", { name: "next" }).click()
    await page.waitForTimeout(1000);
    await page.getByRole("textbox", { name: "password" })

  })

})



test.describe("authentication (Sad Path)", () => {
  test("Form Input Checks", async ({ page }) => {
    await page.goto('https://beatza.me');
    const landingPage = new LandingPage(page)

    await landingPage.signInBtn.click()

    const authForm = new AuthForm(page)
    // auth



  })
  test("Empty Submission", async ({ page }) => {

  })
  test("Invalid Email Format", async ({ page }) => {

  })
  test("Weak Password", async ({ page }) => {

  })
  test("users cannot sneak into restricted pages", async ({ page }) => {

  })
})




















test("Continue with Google auth (persistent Chrome profile)", async () => {
  const userDataDir = path.join(process.cwd(), '.pw-google-profile');
  const context = await chromium.launchPersistentContext(userDataDir, {
    channel: 'chrome',
    headless: true,
  });

  try {
    const page = context.pages()[0] ?? await context.newPage();
    await page.goto('https://beatza.me');
    await page.getByRole("button", { name: "Sign in" }).click();

    const popupPromise = page.waitForEvent('popup');
    await page.getByRole("button", { name: "Continue With Google" }).click();

    const oauthWindow = await popupPromise;
    await oauthWindow.waitForLoadState();

    // await oauthWindow
    // data-identifier
    // If Google session is already saved in this profile, sign-in should complete without typing credentials.

    await expect(oauthWindow).toHaveURL(/^https:\/\/beatza\.me\/home\?accessToken=.+/);
    // await oauthWindow.waitForEvent('close', { timeout: 220000 });

    await context.close();
  } catch (e) {

  }
})
