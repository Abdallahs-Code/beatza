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
  test.describe("Email Field Validation", () => {
    test.beforeEach(async ({ page }) => {
      await page.goto('https://beatza.me');
      const landingPage = new LandingPage(page)
      await landingPage.signInBtn.click()
    })
    const invalidEmails = [
      { desc: 'Empty email', input: '' },
      { desc: 'No @ symbol', input: 'not-an-email' },
      { desc: 'Missing domain', input: 'user@' },
      { desc: 'Missing username', input: '@domain.com' }
    ];
    for (const record of invalidEmails) {
      test(`Should reject: ${record.desc}`, async ({ page }) => {
        const authform = new AuthForm(page);
        await authform.FillEmail(record.input);
        await authform.ClickNextBtn("email");
        await expect(authform.initialForm.getByText("Enter a valid email address or profile url.")).toBeVisible()
      });
    }
  })
  test.describe('Password Field Validation', () => {
    test.beforeEach(async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillEmail('valid.user@example.com');
      await expect(authForm.passwordTxtBox).toBeVisible();
    });

    const invalidPasswords = [
      { desc: 'Empty password', input: '' },
      { desc: 'Too short', input: 'short' },
      { desc: 'No special characters', input: 'Password123' },
      { desc: 'No numbers', input: 'Password@' },
      { desc: 'No uppercase', input: 'password@1' }
    ];

    for (const record of invalidPasswords) {
      test(`Should reject: ${record.desc}`, async ({ page }) => {
        const authForm = new AuthForm(page);
        await authForm.FillPassword(record.input);
        switch (record.desc) {
          case 'Empty password': {
            await expect(authForm.passwordContinueBtn).toBeDisabled()
            break;
          }
          case 'Too short': {
            await expect(authForm.initialForm.getByText("Password must be at least 8 characters long")).toBeVisible()
            break;
          }
          case 'No special characters': {
            await expect(authForm.initialForm.getByText("Password must contain at least one special character")).toBeVisible()
            break;
          }
          case 'No numbers': {
            await expect(authForm.initialForm.getByText("Password must contain at least one number")).toBeVisible()
            break;
          }
          case 'No uppercase': {
            await expect(authForm.initialForm.getByText("Password must contain at least one uppercase letter")).toBeVisible()
            break;
          }
          default:
        }
      });
    }
    test('Should accept valid password and progress', async ({ page }) => {
      const authModal = new AuthForm(page);
      await authModal.FillPassword('ValidPass@123');
      await expect(authModal.displayNameTxtbox).toBeVisible();
    });
  });
  test.describe('display name Validation', () => {
    test.beforeEach(async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillEmail(`valid.user+${Date.now()}@example.com`);
      await authForm.ClickNextBtn("email")
      await authForm.FillPassword("ValidPass@123")
      await authForm.ClickBackBtn("password")
      await authForm.FillDate("February", 5, 2005)
      await authForm.FillGender("Male")
    });
    test("display reject", async ({ page }) => {
      const authForm = new AuthForm(page);
      authForm.displayNameTxtbox.fill("")
      await expect(authForm.detailsContinueBtn).toBeDisabled()
    })
    test("display name validation", async ({ page }) => {
      const authForm = new AuthForm(page);
      authForm.displayNameTxtbox.fill("a")
      await expect(authForm.detailsContinueBtn).toBeEnabled()
    })
  });
  test.describe('Date of Birth Validation', () => {
    test.beforeEach(async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillEmail(`valid.user+${Date.now()}@example.com`);
      await authForm.ClickNextBtn("email")
      await authForm.FillPassword("ValidPass@123")
      await authForm.ClickNextBtn("password")
      await authForm.FillGender("Male")
    });
    test("dob reject", async ({ page }) => {
      const authForm = new AuthForm(page);
      await expect(authForm.detailsContinueBtn).toBeDisabled()
    })
    test("dob reject2", async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillDate("March", 21, 2020)
      await authForm.ClickNextBtn("details")
      await expect(authForm.detailsForm.getByText("Validation failed")).toBeVisible()
    })
    test("dob accept", async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillDate("March", 21, 2005)
      await expect(authForm.detailsContinueBtn).toBeEnabled()
    })
  });
  test.describe('gender Validation', () => {
    test.beforeEach(async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillEmail(`valid.user+${Date.now()}@example.com`);
      await authForm.ClickNextBtn("email")
      await authForm.FillPassword("ValidPass@123")
      await authForm.ClickNextBtn("password")
      await authForm.FillDate("February", 5, 2005)
    });
    test("display reject", async ({ page }) => {
      const authForm = new AuthForm(page);
      await expect(authForm.detailsContinueBtn).toBeDisabled()
    })
    test("display name validation", async ({ page }) => {
      const authForm = new AuthForm(page);
      await authForm.FillGender("Male")
      await expect(authForm.detailsContinueBtn).toBeEnabled()
    })
  });

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
