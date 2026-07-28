# Licence service

The smallest thing that can turn "Paddle says this person paid" into "this key works". One file, `src/index.js`, running on Cloudflare Workers with one KV namespace.

## Why it exists

Two constraints meet here:

- **Paddle Billing has no licence keys.** Paddle-led fulfilment was retired, leaving webhooks and nothing else. Whoever sells through Paddle mints their own keys.
- **A build from GitHub Releases cannot use store billing.** Google Play refuses to serve `BillingClient` to an app it did not install and sign, and no desktop platform offers billing Flutter can reach. The licence key is the only route that works on every platform the app ships to.

The app knows nothing about Paddle — it talks only to these endpoints. That is what makes the payment provider replaceable: if a better merchant of record turns up, `paddleWebhook` and the offers config change, and every build already in the wild keeps working.

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/v1/offers` | What is on sale, priced and linked. `{"offers":[]}` until Paddle is live |
| `POST` | `/v1/licenses/activate` | `{key, deviceName}` → binds the key to a device |
| `POST` | `/v1/licenses/validate` | `{key, instanceId}` → re-answers for a bound device |
| `POST` | `/v1/paddle/webhook` | Paddle's subscription and transaction events |
| `GET` | `/claim?_ptxn=…` | The page a buyer lands on, showing their key |
| `GET` | `/health` | `{"ok":true}` |

**The one rule the app depends on:** every answer the service *means* comes back as `200`, including refusals — a dead key is `{"verdict":"inactive"}`, never a `403`. Anything else at all is read by the app as "no answer", and it falls back on its own offline grace period. Break that rule and offline users start being told their subscription ended.

Verdicts are `active`, `inactive`, `unknown` and `activationLimitReached`. Only `active` carries `instanceId`, `planId` and `expiresAt`.

## Setup

```bash
npm install -g wrangler
wrangler login

wrangler kv namespace create LICENSES     # paste the id into wrangler.toml
wrangler secret put PADDLE_WEBHOOK_SECRET # from Paddle → Notifications
wrangler deploy
```

Then in Paddle:

- **Notification destination** → `https://archonex-license.<subdomain>.workers.dev/v1/paddle/webhook`, subscribed to `subscription.created`, `subscription.updated`, `subscription.canceled` and `transaction.completed`.
- **Checkout success URL** → `https://archonex-license.<subdomain>.workers.dev/claim`. Paddle appends `_ptxn` itself.

Finally, publish what is for sale. Until this key exists the shop is shut, which the paywall states plainly:

```bash
wrangler kv key put --binding LICENSES config:offers '{
  "offers": [
    {"id":"pri_MONTHLY","period":"monthly","priceLabel":"$4.99 / month","checkoutUrl":"https://…"},
    {"id":"pri_YEARLY","period":"yearly","priceLabel":"$34.99 / year","checkoutUrl":"https://…"}
  ]
}'
```

`id` must be the Paddle price ID, because that is what arrives in the webhook as the plan. `priceLabel` is shown to the user verbatim — it is the one string in the whole system that has to be kept in step with Paddle by hand, and it is deliberately not composed by the app.

## Tests

```bash
cd server/license
node --test
```

No dependencies and no test framework — `node:test` is built in. What is covered is `src/lib.js`, which holds the parts where a mistake costs money: the webhook signature (a forged one accepted means free licences, a genuine one rejected means no keys issued), key minting and normalisation, and the escaping on the claim page. The request routing in `src/index.js` is left to `wrangler dev` and a test event from the Paddle dashboard, because testing it would mean reimplementing KV.

## Deployment

`.github/workflows/deploy-license.yml` deploys on pushes to `main` that touch `server/license/**`. It needs two repository secrets: `CLOUDFLARE_API_TOKEN` (scope: *Edit Cloudflare Workers*) and `CLOUDFLARE_ACCOUNT_ID`.

## What it is not

Not an authority on whether the app is genuine. The check runs on the user's own machine, so anyone willing to patch a binary can skip it entirely. Closing that would mean converting files on a server, which is the opposite of what this app is. This is a receipt desk, and it is worth what a receipt is worth.

Keys are stored in KV in plain text. They are bearer tokens for a $5 subscription, not passwords, and hashing them would break the one operation support actually needs: looking a customer's key up when they ask.
