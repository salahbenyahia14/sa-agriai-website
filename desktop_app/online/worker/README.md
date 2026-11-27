# SA AgriAI Online API

This Worker serves the Flutter Web build and provides the first shared backend for accounts, marketplace listings, and community posts.

## Cloudflare resources
- Worker: sa-agriai-app
- D1 database: sa-agriai-app
- D1 binding: DB
- Static assets binding: ASSETS
- Session cookie: HttpOnly, Secure, SameSite=Lax
- Password reset tokens: random, single-use, 20-minute expiry; only a SHA-256 hash is stored.

The first migration is in migrations/0001_initial.sql.

## EmailJS secrets
The Worker sends reset messages server-side. Never put these values in Flutter or commit them:
- EMAILJS_SERVICE_ID
- EMAILJS_TEMPLATE_ID
- EMAILJS_PUBLIC_KEY
- EMAILJS_PRIVATE_KEY

Create one EmailJS template with these dynamic variables:
- Recipient address: {{to_email}}
- Subject: SA AgriAI — Password reset
- Message includes {{reset_link}} and {{expiry_minutes}}.

Connect the SA AgriAI sending mailbox to EmailJS and copy its four identifiers/keys into GitHub Actions secrets. EmailJS Free currently allows 200 requests per month; a different transactional mail provider can replace it later without changing the account reset contract.

## API routes
- GET /api/health
- POST /api/auth/register
- POST /api/auth/login
- GET /api/auth/me
- POST /api/auth/logout
- POST /api/auth/forgot-password
- POST /api/auth/reset-password
- GET|POST /api/listings, DELETE /api/listings/:id
- GET|POST /api/posts, DELETE /api/posts/:id

Listing and post reads require an authenticated account. All users can read active public entries; only their owner can delete an entry. Phone numbers entered in a marketplace listing are visible to signed-in users.

## Account recovery rules
For a forgotten password, use the in-app email reset flow. Support is not needed. Requests receive the same public response whether the account exists or not. Deleted-account recovery and account ownership disputes remain manual support cases via saagriateam@gmail.com.

## Security notes
- Passwords are never stored in clear text.
- Reset tokens are not stored in clear text and are invalidated after use or expiry.
- Successful reset revokes existing sessions.
- Login, registration, reset, and forgot-password endpoints have server-side request limits.
- Do not log passwords, reset tokens, or mail-provider credentials.
- Before public launch, complete the UI review, deploy with HTTPS, configure the EmailJS sender/template, and test password reset end-to-end with an ordinary external email address.