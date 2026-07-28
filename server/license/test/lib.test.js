import assert from 'node:assert/strict';
import test from 'node:test';

import {
  KEY_ALPHABET,
  SIGNATURE_TOLERANCE_SECONDS,
  escapeHtml,
  expiryOf,
  hmacSha256Hex,
  isSignedByPaddle,
  normaliseKey,
  planIdOf,
  randomKey,
  timingSafeEqual,
} from '../src/lib.js';

const SECRET = 'pdl_ntfset_test_secret';
const BODY = '{"event_type":"subscription.created","data":{"id":"sub_1"}}';
const NOW = 1_770_000_000;

/** A header Paddle would have sent, for whatever timestamp the test wants. */
async function signedHeader(timestamp = NOW, body = BODY, secret = SECRET) {
  return `ts=${timestamp};h1=${await hmacSha256Hex(secret, `${timestamp}:${body}`)}`;
}

const clock = () => NOW;

test('a genuine signature is accepted', async () => {
  assert.equal(await isSignedByPaddle(BODY, await signedHeader(), SECRET, clock), true);
});

test('a body altered by one character is rejected', async () => {
  // The whole point of the check. If this ever passes, anyone can grant
  // themselves a licence by posting to the webhook.
  const header = await signedHeader();

  assert.equal(await isSignedByPaddle(`${BODY} `, header, SECRET, clock), false);
});

test('the wrong secret is rejected', async () => {
  const header = await signedHeader(NOW, BODY, 'someone_elses_secret');

  assert.equal(await isSignedByPaddle(BODY, header, SECRET, clock), false);
});

test('a replayed signature falls outside the tolerance window', async () => {
  const stale = NOW - SIGNATURE_TOLERANCE_SECONDS - 1;

  assert.equal(await isSignedByPaddle(BODY, await signedHeader(stale), SECRET, clock), false);
});

test('a signature just inside the window still counts', async () => {
  const recent = NOW - SIGNATURE_TOLERANCE_SECONDS + 1;

  assert.equal(await isSignedByPaddle(BODY, await signedHeader(recent), SECRET, clock), true);
});

test('a timestamp from the future is rejected as far as it is out', async () => {
  const ahead = NOW + SIGNATURE_TOLERANCE_SECONDS + 1;

  assert.equal(await isSignedByPaddle(BODY, await signedHeader(ahead), SECRET, clock), false);
});

test('a malformed or missing header is rejected, never trusted by default', async () => {
  for (const header of ['', 'garbage', 'ts=;h1=', 'h1=abc', `ts=not-a-number;h1=abc`, null]) {
    assert.equal(await isSignedByPaddle(BODY, header, SECRET, clock), false, `header: ${header}`);
  }
});

test('no configured secret rejects everything', async () => {
  // A worker deployed before `wrangler secret put` must refuse webhooks rather
  // than accept them all.
  assert.equal(await isSignedByPaddle(BODY, await signedHeader(), '', clock), false);
});

test('comparison is length-aware and value-aware', () => {
  assert.equal(timingSafeEqual('abc', 'abc'), true);
  assert.equal(timingSafeEqual('abc', 'abd'), false);
  assert.equal(timingSafeEqual('abc', 'abcd'), false);
});

test('a minted key is readable and unambiguous', () => {
  const key = randomKey();

  assert.match(key, /^ARCX(-[A-Z2-9]{5}){4}$/);
  // 0/O and 1/I would come back from customers transcribed wrongly.
  assert.equal(KEY_ALPHABET.includes('0'), false);
  assert.equal(KEY_ALPHABET.includes('O'), false);
  assert.equal(KEY_ALPHABET.includes('1'), false);
  assert.equal(KEY_ALPHABET.includes('I'), false);
});

test('minted keys do not repeat', () => {
  const keys = new Set(Array.from({ length: 500 }, randomKey));

  assert.equal(keys.size, 500);
});

test('a key retyped from a receipt still matches', () => {
  assert.equal(normaliseKey('  arcx-ab2cd-ef3gh-jk4lm-np5qr \n'), 'ARCX-AB2CD-EF3GH-JK4LM-NP5QR');
  assert.equal(normaliseKey('ARCX AB2CD'), 'ARCXAB2CD');
});

test('unusable input normalises to nothing rather than to something', () => {
  assert.equal(normaliseKey(''), '');
  assert.equal(normaliseKey('   '), '');
  assert.equal(normaliseKey(null), '');
  assert.equal(normaliseKey(42), '');
  assert.equal(normaliseKey('A'.repeat(65)), '');
});

test('the plan is the first price ID, and missing items are not a crash', () => {
  assert.equal(planIdOf({ items: [{ price: { id: 'pri_monthly' } }] }), 'pri_monthly');
  assert.equal(planIdOf({ items: [] }), null);
  assert.equal(planIdOf({}), null);
  assert.equal(planIdOf({ items: [{}] }), null);
});

test('expiry prefers the billing period Paddle is currently in', () => {
  assert.equal(
    expiryOf({ current_billing_period: { ends_at: '2026-08-01T00:00:00Z' }, next_billed_at: '2026-09-01T00:00:00Z' }),
    '2026-08-01T00:00:00Z',
  );
  assert.equal(expiryOf({ next_billed_at: '2026-09-01T00:00:00Z' }), '2026-09-01T00:00:00Z');
  assert.equal(expiryOf({}), null);
});

test('the claim page cannot be used to inject markup', () => {
  assert.equal(escapeHtml('<script>alert(1)</script>'), '&lt;script&gt;alert(1)&lt;/script&gt;');
  assert.equal(escapeHtml(`"'&`), '&quot;&#39;&amp;');
});
