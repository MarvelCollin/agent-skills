# Sign Up, Sign In and Recovery

The doors into the product. Every extra field or step here loses users, and every unclear error locks them out.

## Sign Up

- Ask the minimum: email and password, or a single sign on button. Name, company and role can come later in onboarding
- Offer the sign in methods the audience uses (Google or Microsoft for business tools, SSO for enterprise, passkeys where supported). Social buttons say "Continue with Google"
- One password field with a show password toggle. No "confirm password" field and no "confirm email" field
- Password rules visible before typing and ticked off live. Favor length (at least 12 characters) over symbol rules. Allow paste and password managers (`autocomplete="new-password"`)
- Terms and privacy links near the button. Marketing consent is a separate unchecked box
- After sign up, verify email without blocking: let the user in, remind them with a banner, and send a code or link

## Sign In

- Email first, then password on the same page or the next. `autocomplete="username"` and `current-password`
- "Forgot password" link next to the password field, not below the button
- Show password toggle. "Keep me signed in" only when sessions are otherwise short
- Errors never reveal whether the email exists: "Email or password is incorrect". After repeated failures, slow down and offer reset, never a silent lock
- Return the user to the page they were trying to reach

## Password Reset and Magic Links

- Ask for the email, then always show the same message: "If an account exists for that email, we sent a link. It expires in 30 minutes." Offer to resend after a short wait
- The link opens a page with one new password field and a show toggle, then signs the user in
- Magic links and one time codes: show which address it went to, a resend option with a countdown, a way to change the email, and a code input as an alternative to clicking (better for users on another device). Code input accepts paste, has `autocomplete="one-time-code"`, and submits when complete
- Expired or used links explain that and offer a new one in one click

## Two Factor

- Authenticator app as default, with a QR code and the setup key as text. SMS only as a fallback. Passkeys or security keys for higher security
- Backup codes shown once with download and copy, and a reminder to store them
- At sign in, the code field focuses automatically. "Trust this device for 30 days" option. "Use a backup code" link
- Recovery path when the device is lost, explained before it is needed

## SSO and Enterprise

- "Sign in with SSO" asks for the work email and routes to the right identity provider
- When SSO is enforced, password fields disappear for that domain with an explanation

## Session Expiry

- Warn before a timeout in long forms, with "Stay signed in"
- After expiry, sign in again in place and return to the same page with unsaved input kept

## Check

1. Can a new user sign up in under a minute with only an email and password?
2. Does a wrong password give a neutral error and a nearby reset link?
3. Does a reset or magic link work on a different device through a code?
4. Do password managers fill and save correctly?
5. Does an expired session return the user to where they were?

## Sources

- [A Checklist for Registration and Login Forms on Mobile, NN/g](https://www.nngroup.com/articles/checklist-registration-login/)
- [Password Creation: 3 Ways to Make It Easier, NN/g](https://www.nngroup.com/articles/password-creation/)
- [Rethinking Authentication UX, Smashing Magazine](https://www.smashingmagazine.com/2022/08/authentication-ux-design-guidelines/)
- [NIST SP 800-63B Digital Identity Guidelines](https://pages.nist.gov/800-63-4/sp800-63b.html)
