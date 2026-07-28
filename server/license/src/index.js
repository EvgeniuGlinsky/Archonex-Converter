/**
 * The licence service.
 *
 * Three jobs, and nothing else: tell the app what is on sale, mint a key when
 * Paddle says someone paid, and answer whether a key is good.
 *
 * WHY THIS EXISTS AT ALL. Paddle Billing has no licence keys — Paddle-led
 * fulfilment was retired, leaving only webhooks — and an app distributed through
 * GitHub Releases cannot use store billing either, because Google Play refuses
 * to serve `BillingClient` to an app it did not install and sign. Something has
 * to hold the mapping from "this subscription is paid" to "this key works", and
 * this is the smallest thing that can.
 *
 * WHY IT IS WORTH THE TROUBLE. The payment provider is invisible to the app: it
 * talks only to these endpoints. If Paddle's verification drags on, or a better
 * merchant of record turns up, only `paddleWebhook` and `readOffers` change and
 * every build already in the wild keeps working.
 *
 * WHAT IT IS NOT. Not an authority on whether the app is genuine — the check
 * runs on the user's machine, and anyone willing to patch a binary can skip it.
 * It is a receipt desk, and it is worth what a receipt is worth.
 *
 * Bindings, all set outside this file:
 *   LICENSES              KV namespace — see the key layout below
 *   PADDLE_WEBHOOK_SECRET secret, from Paddle's notification settings
 *   MAX_ACTIVATIONS       var, defaults to 3 devices per key
 *
 * KV layout:
 *   license:<KEY>   { planId, status, expiresAt, subscriptionId, instances[] }
 *   sub:<ID>        the key minted for that Paddle subscription
 *   txn:<ID>        the key belonging to that Paddle transaction, for /claim
 *   config:offers   { offers: [{ id, period, priceLabel, checkoutUrl }] }
 */

import {
  escapeHtml,
  expiryOf,
  isSignedByPaddle,
  normaliseKey,
  planIdOf,
  randomId,
  randomKey,
} from './lib.js';

const DEFAULT_MAX_ACTIVATIONS = 3;

/**
 * Paddle statuses that entitle a device.
 *
 * `past_due` is deliberately included: Paddle is still retrying the card, and
 * cutting a subscriber off during dunning punishes them for their bank's
 * timing. `paused` and `canceled` are not.
 */
const ENTITLING_STATUSES = new Set(['active', 'trialing', 'past_due']);

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    try {
      return await route(request, env, url);
    } catch (error) {
      // Never leak internals to a public endpoint, and never answer a licence
      // question with a guess: a 500 is what the app reads as "no answer", and
      // it will fall back on its own grace period.
      console.error('unhandled', error && error.stack ? error.stack : error);

      return json({ error: 'internal' }, 500);
    }
  },
};

async function route(request, env, url) {
  const { pathname } = url;

  if (request.method === 'OPTIONS') {
    return preflight();
  }

  if (request.method === 'GET' && pathname === '/health') {
    return json({ ok: true });
  }

  if (request.method === 'GET' && pathname === '/v1/offers') {
    return json(await readOffers(env));
  }

  if (request.method === 'POST' && pathname === '/v1/licenses/activate') {
    return activate(request, env);
  }

  if (request.method === 'POST' && pathname === '/v1/licenses/validate') {
    return validate(request, env);
  }

  if (request.method === 'POST' && pathname === '/v1/paddle/webhook') {
    return paddleWebhook(request, env);
  }

  if (request.method === 'GET' && pathname === '/claim') {
    return claim(env, url.searchParams.get('_ptxn'));
  }

  return json({ error: 'not_found' }, 404);
}

/* ------------------------------------------------------------------ offers */

/**
 * What is on sale, exactly as configured.
 *
 * An empty list is a valid answer, and the one that ships until Paddle has
 * approved the account. The app's paywall says the shop is shut rather than
 * inventing a price, so there is nothing to hurry here.
 */
async function readOffers(env) {
  const stored = await env.LICENSES.get('config:offers', 'json');

  if (!stored || !Array.isArray(stored.offers)) {
    return { offers: [] };
  }

  return { offers: stored.offers };
}

/* ---------------------------------------------------------------- licences */

/**
 * Binds a key to one device.
 *
 * Re-activating from a device already on the list is not an error and does not
 * spend a slot: reinstalling the app, or clearing its data, must not cost the
 * user one of their three devices.
 */
async function activate(request, env) {
  const body = await readJson(request);
  const key = normaliseKey(body.key);
  const deviceName = typeof body.deviceName === 'string' ? body.deviceName.slice(0, 120) : 'unknown';

  if (!key) {
    return json({ verdict: 'unknown' });
  }

  const record = await env.LICENSES.get(`license:${key}`, 'json');

  if (!record) {
    return json({ verdict: 'unknown' });
  }

  if (!ENTITLING_STATUSES.has(record.status)) {
    return json({ verdict: 'inactive' });
  }

  const instances = Array.isArray(record.instances) ? record.instances : [];
  const existing = instances.find((instance) => instance.name === deviceName);

  if (existing) {
    return json(activeAnswer(record, existing.id));
  }

  const limit = Number(env.MAX_ACTIVATIONS || DEFAULT_MAX_ACTIVATIONS);

  if (instances.length >= limit) {
    return json({ verdict: 'activationLimitReached' });
  }

  const instance = { id: randomId(), name: deviceName, at: new Date().toISOString() };
  record.instances = [...instances, instance];
  await env.LICENSES.put(`license:${key}`, JSON.stringify(record));

  return json(activeAnswer(record, instance.id));
}

/**
 * Re-answers for a device that already activated.
 *
 * An instance the service has never heard of is `unknown` rather than
 * `inactive`: the licence may be perfectly alive, but this device's claim on it
 * is not, and the app should ask the user for the key again rather than tell
 * them their subscription ended.
 */
async function validate(request, env) {
  const body = await readJson(request);
  const key = normaliseKey(body.key);
  const instanceId = typeof body.instanceId === 'string' ? body.instanceId : '';

  if (!key || !instanceId) {
    return json({ verdict: 'unknown' });
  }

  const record = await env.LICENSES.get(`license:${key}`, 'json');

  if (!record) {
    return json({ verdict: 'unknown' });
  }

  const instances = Array.isArray(record.instances) ? record.instances : [];

  if (!instances.some((instance) => instance.id === instanceId)) {
    return json({ verdict: 'unknown' });
  }

  if (!ENTITLING_STATUSES.has(record.status)) {
    return json({ verdict: 'inactive' });
  }

  return json(activeAnswer(record, instanceId));
}

function activeAnswer(record, instanceId) {
  return {
    verdict: 'active',
    instanceId,
    planId: record.planId,
    expiresAt: record.expiresAt || null,
  };
}

/* --------------------------------------------------------------- webhooks */

/**
 * Paddle telling us what changed.
 *
 * The signature is checked before anything is read, and a request that fails it
 * is answered 401 without a hint as to why. Everything past that point is
 * idempotent: Paddle retries, and a retry must not mint a second key for one
 * subscription.
 */
async function paddleWebhook(request, env) {
  const raw = await request.text();
  const signature = request.headers.get('Paddle-Signature') || '';

  if (!(await isSignedByPaddle(raw, signature, env.PADDLE_WEBHOOK_SECRET))) {
    return json({ error: 'unauthorised' }, 401);
  }

  let event;
  try {
    event = JSON.parse(raw);
  } catch (_) {
    return json({ error: 'bad_request' }, 400);
  }

  const type = event.event_type;
  const data = event.data || {};

  if (type === 'subscription.created' || type === 'subscription.updated' || type === 'subscription.canceled') {
    await recordSubscription(env, type, data);

    return json({ ok: true });
  }

  if (type === 'transaction.completed') {
    await linkTransaction(env, data);

    return json({ ok: true });
  }

  // Anything else is acknowledged and ignored, so Paddle stops retrying it.
  return json({ ok: true, ignored: type || 'unknown' });
}

async function recordSubscription(env, type, data) {
  const subscriptionId = data.id;

  if (!subscriptionId) {
    return;
  }

  const key = (await env.LICENSES.get(`sub:${subscriptionId}`)) || (await mintKey(env, subscriptionId));
  const stored = (await env.LICENSES.get(`license:${key}`, 'json')) || { instances: [] };

  // `subscription.canceled` does not always carry a status, so the event type
  // is the authority for that one.
  const status = type === 'subscription.canceled' ? 'canceled' : data.status || stored.status || 'active';

  const record = {
    ...stored,
    subscriptionId,
    status,
    planId: planIdOf(data) || stored.planId || null,
    expiresAt: expiryOf(data) || stored.expiresAt || null,
    instances: Array.isArray(stored.instances) ? stored.instances : [],
  };

  await env.LICENSES.put(`license:${key}`, JSON.stringify(record));

  // The transaction that started the subscription, so /claim works even if the
  // transaction.completed event never arrives.
  if (data.transaction_id) {
    await env.LICENSES.put(`txn:${data.transaction_id}`, key);
  }
}

/**
 * Mints one key per subscription, and only once.
 *
 * The `sub:` entry is written first and is what makes a retried webhook find
 * the existing key instead of creating a second one.
 */
async function mintKey(env, subscriptionId) {
  const key = randomKey();
  await env.LICENSES.put(`sub:${subscriptionId}`, key);

  return key;
}

async function linkTransaction(env, data) {
  if (!data.id || !data.subscription_id) {
    return;
  }

  const key = await env.LICENSES.get(`sub:${data.subscription_id}`);

  if (key) {
    await env.LICENSES.put(`txn:${data.id}`, key);
  }
}

/* ------------------------------------------------------------------ claim */

/**
 * The page Paddle returns the buyer to, showing the key it just paid for.
 *
 * There is no email step yet, so this page is how the key is delivered. Paddle
 * appends `_ptxn` to the success URL; the webhook that maps it may land a second
 * or two later, so a miss says "not ready" and invites a refresh rather than
 * claiming the key does not exist.
 */
async function claim(env, transactionId) {
  if (!transactionId) {
    return html(page('Nothing to show', 'This page needs the link from your receipt.'), 400);
  }

  const key = await env.LICENSES.get(`txn:${transactionId}`);

  if (!key) {
    return html(
      page(
        'Almost there',
        'Your payment went through and the licence key is being issued. Refresh this page in a few seconds.',
      ),
      200,
    );
  }

  return html(
    page(
      'Your licence key',
      'Open Archonex Converter, go to the subscription screen and paste this key. Keep a copy — it activates up to three devices.',
      key,
    ),
  );
}

function page(title, message, key) {
  const safeKey = key ? escapeHtml(key) : '';

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} — Archonex Converter</title>
<style>
  :root { color-scheme: light dark; }
  body { font-family: system-ui, sans-serif; margin: 0; min-height: 100vh;
         display: grid; place-items: center; padding: 1.5rem; }
  main { max-width: 34rem; }
  h1 { font-size: 1.5rem; margin: 0 0 .75rem; }
  p { line-height: 1.6; margin: 0 0 1.25rem; }
  code { display: block; font-size: 1.25rem; letter-spacing: .08em;
         padding: 1rem; border-radius: .5rem; word-break: break-all;
         background: rgba(127,127,127,.16); }
</style>
</head>
<body>
<main>
  <h1>${escapeHtml(title)}</h1>
  <p>${escapeHtml(message)}</p>
  ${safeKey ? `<code>${safeKey}</code>` : ''}
</main>
</body>
</html>`;
}

/* ----------------------------------------------------------------- plumbing */

async function readJson(request) {
  try {
    const body = await request.json();

    return body && typeof body === 'object' ? body : {};
  } catch (_) {
    return {};
  }
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      ...corsHeaders(),
    },
  });
}

function html(body, status = 200) {
  return new Response(body, {
    status,
    headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' },
  });
}

/**
 * Open to any origin, because there is nothing here to protect with an origin:
 * no cookies, no session, and the licence key is its own credential.
 */
function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Accept',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };
}

function preflight() {
  return new Response(null, { status: 204, headers: corsHeaders() });
}
