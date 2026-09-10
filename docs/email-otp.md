# Email verification codes

LaterBox supports six digit email codes on web, macOS, iOS, Android, and Windows. The same authentication screens support account confirmation after password sign up and passwordless sign in for existing accounts.

## Supabase configuration

In the Supabase dashboard, open **Authentication > Providers > Email** and enable **Confirm email** when new accounts must verify their address.

Then open **Authentication > Email Templates** and make both templates display the token rather than only a confirmation link:

- **Confirm signup** must include `{{ .Token }}`.
- **Magic Link** must include `{{ .Token }}`.

For example:

```html
<h2>Your LaterBox verification code</h2>
<p>Enter this six digit code in LaterBox:</p>
<p style="font-size: 32px; font-weight: 800; letter-spacing: 8px;">{{ .Token }}</p>
<p>This code expires soon. If you did not request it, you can ignore this email.</p>
```

Set the email OTP length to `6`. Choose an expiry that balances usability and security. The repository's local Supabase configuration uses six digits and a one hour expiry.

Passwordless sign in is restricted to existing accounts. LaterBox sends `shouldCreateUser: false`, so requesting a sign in code never creates an account silently.

## Supported flows

- Password sign up with Confirm email enabled opens the verification code screen.
- Password sign up with Confirm email disabled signs in immediately.
- **Email me a sign in code** sends a code to an existing account.
- **Send a new code** resends the correct sign up or sign in email.
- Successful verification returns to the requested destination, including a selected subscription plan or extension connection.

