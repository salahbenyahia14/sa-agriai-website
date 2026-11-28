# Deploying SA AgriAI Online

The online app has a separate Worker from the existing public information website. It does not overwrite the existing website deployment.

## GitHub Actions secrets
In GitHub repository Settings, add these Actions secrets:
- CLOUDFLARE_ACCOUNT_ID
- CLOUDFLARE_API_TOKEN — token with Workers Scripts: Edit and D1: Edit permissions for this account.
- EMAILJS_SERVICE_ID
- EMAILJS_TEMPLATE_ID
- EMAILJS_PUBLIC_KEY
- EMAILJS_PRIVATE_KEY

The workflow creates the D1 database named sa-agriai-app if it does not exist, applies the checked-in migrations, builds Flutter Web, and deploys the sa-agriai-app Worker.

Expected workers.dev URL:
https://sa-agriai-app.salahbenyahia687.workers.dev

This URL is live only after deployment completes and the workers.dev subdomain is enabled on the account.

## EmailJS setup
1. Create a free EmailJS account.
2. Connect the sending mailbox saagriateam@gmail.com.
3. Create a password-reset email template.
4. Set the template recipient field to {{to_email}}.
5. Include {{reset_link}} as a clickable link and state that it expires after {{expiry_minutes}} minutes.
6. Add the service ID, template ID, public key, and private key to GitHub Actions secrets.

Keep the EmailJS private key only in GitHub Secrets/Cloudflare Worker secrets. Never add it to Dart, browser JavaScript, or the repository.

## Free-tier expectations
Cloudflare Workers and D1 have free-tier usage limits. D1 queries stop working until the daily reset if account row-read or row-write limits are exceeded. EmailJS Free currently has 200 requests per month. These services are suitable for an initial pilot, not unlimited traffic.

## Local API development
Use a local D1 database with Wrangler and apply migrations before running the Worker. Do not point local development at production data unless explicitly intended.

## Launch verification
The web deployment workflow builds the Flutter Web client, provisions the Cloudflare D1 database, applies migrations, and deploys the Worker plus web assets when all required GitHub Actions secrets are configured. A successful build alone does not mean the online services were deployed; verify the `deploy-cloudflare` job and `/api/health` endpoint after each release.
