# Cloudflare Worker API setup for SA AgriAI

This project currently serves static pages. The API worker in \`cloudflare-worker.js\` adds the server-side integrations without exposing provider keys in browser code.

## Required bindings and secrets
- Static Assets binding named \`ASSETS\` (point it at the site's published static assets).
- KV namespace binding named \`SA_CACHE\` for cached searches and incoming questions.
- Secret \`YOUTUBE_API_KEY\` (YouTube Data API v3).
- Secret \`UNSPLASH_ACCESS_KEY\` (Unsplash API access key).
- Secret \`ADMIN_TOKEN\` (a long random token for the private questions dashboard).

## Routes
- \`GET /api/search?type=videos&q=...\`: YouTube Data API search, restricted to embeddable videos and region DZ; cached for 30 minutes.
- \`GET /api/search?type=images&q=...\`: Unsplash API search with attribution; cached for 30 minutes. Wikimedia Commons search is also performed from the browser using its public API.
- \`POST /api/questions\`: stores a visitor question in KV.
- \`GET /api/questions\`: returns stored questions only when the ADMIN_TOKEN bearer token is correct.
- \`/admin.html\`: private question viewer.

## Important
Do not commit API keys or the admin token. Add them in Cloudflare Worker Settings → Variables and Secrets. Bind the KV namespace in Worker Settings → Bindings. The worker expects the static assets binding to be named \`ASSETS\`. Until this worker is deployed with these bindings, the site keeps its internal article results and Wikimedia Commons fallback; the YouTube and Unsplash server endpoints will remain inactive.
