/**
 * The parts of the licence service that are pure functions, split out so they
 * can be tested with `node --test`.
 *
 * Everything here is either security-critical or user-facing: a webhook
 * signature that is checked wrongly means either forged payments accepted or
 * real ones dropped, and a key that normalises inconsistently means a customer
 * whose key works on one screen and not the next.
 */

/** How far out of date a webhook signature may be, against replay. */
export const SIGNATURE_TOLERANCE_SECONDS = 300;

/** Ambiguous characters left out, because these keys get read aloud and retyped. */
export const KEY_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/**
 * Verifies Paddle's `ts=…;h1=…` header.
 *
 * The signed payload is the timestamp and the *raw* body joined by a colon, so
 * the body must never be parsed and re-serialised before getting here — one
 * whitespace difference and every webhook fails.
 *
 * [nowSeconds] is injectable because the tolerance window is otherwise
 * untestable without waiting five minutes.
 */
export async function isSignedByPaddle(rawBody, header, secret, nowSeconds = () => Math.floor(Date.now() / 1000)) {
  if (!secret || !header) {
    return false;
  }

  const parts = parseSignatureHeader(header);
  const timestamp = parts.get('ts');
  const expected = parts.get('h1');

  if (!timestamp || !expected || !/^\d+$/.test(timestamp)) {
    return false;
  }

  const age = Math.abs(nowSeconds() - Number(timestamp));

  if (!Number.isFinite(age) || age > SIGNATURE_TOLERANCE_SECONDS) {
    return false;
  }

  const actual = await hmacSha256Hex(secret, `${timestamp}:${rawBody}`);

  return timingSafeEqual(actual, expected);
}

export function parseSignatureHeader(header) {
  return new Map(
    String(header)
      .split(';')
      .map((piece) => {
        const at = piece.indexOf('=');

        return at === -1 ? [piece.trim(), ''] : [piece.slice(0, at).trim(), piece.slice(at + 1).trim()];
      }),
  );
}

export async function hmacSha256Hex(secret, message) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  return toHex(await crypto.subtle.sign('HMAC', key, encoder.encode(message)));
}

/** Compares without leaking where the first difference was. */
export function timingSafeEqual(a, b) {
  if (a.length !== b.length) {
    return false;
  }

  let difference = 0;
  for (let i = 0; i < a.length; i += 1) {
    difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return difference === 0;
}

export function toHex(buffer) {
  return [...new Uint8Array(buffer)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export function randomKey() {
  return `ARCX-${[0, 1, 2, 3].map(() => randomChars(5)).join('-')}`;
}

export function randomChars(length) {
  const bytes = crypto.getRandomValues(new Uint8Array(length));

  return [...bytes].map((byte) => KEY_ALPHABET[byte % KEY_ALPHABET.length]).join('');
}

export function randomId() {
  return `inst_${randomChars(16).toLowerCase()}`;
}

/**
 * Upper-cased and stripped of whitespace, so a key retyped from a receipt still
 * matches the one that was issued.
 *
 * Returns an empty string for anything unusable, which every caller reads as
 * "no such key" rather than looking it up.
 */
export function normaliseKey(value) {
  if (typeof value !== 'string') {
    return '';
  }

  const cleaned = value.trim().toUpperCase().replace(/\s+/g, '');

  return cleaned.length > 0 && cleaned.length <= 64 ? cleaned : '';
}

/** The Paddle price ID, which is what the app stores as the plan. */
export function planIdOf(data) {
  const items = Array.isArray(data.items) ? data.items : [];
  const first = items[0];

  return (first && first.price && first.price.id) || null;
}

export function expiryOf(data) {
  const period = data.current_billing_period;

  return (period && period.ends_at) || data.next_billed_at || null;
}

export function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
