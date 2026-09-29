// Test delle parti pure delle Edge Function: `deno test supabase/functions`.
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import { base64UrlDecode, base64UrlEncode, safeEqual, sha256Hex } from "./http.ts";
import { mapState } from "./play.ts";
import { verifyStripeSignature } from "./stripe.ts";

async function stripeHeader(payload: string, secret: string, timestamp: number): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${timestamp}.${payload}`)));
  return `t=${timestamp},v1=${[...mac].map((b) => b.toString(16).padStart(2, "0")).join("")}`;
}

Deno.test("una firma Stripe valida viene accettata", async () => {
  const now = Math.floor(Date.now() / 1000);
  const header = await stripeHeader('{"id":"evt_1"}', "whsec_test", now);
  assert(await verifyStripeSignature('{"id":"evt_1"}', header, "whsec_test"));
});

Deno.test("firma sbagliata, contenuto alterato o evento vecchio vengono rifiutati", async () => {
  const now = Math.floor(Date.now() / 1000);
  const header = await stripeHeader('{"id":"evt_1"}', "whsec_test", now);
  assertFalse(await verifyStripeSignature('{"id":"evt_2"}', header, "whsec_test"));
  assertFalse(await verifyStripeSignature('{"id":"evt_1"}', header, "whsec_altro"));
  assertFalse(await verifyStripeSignature('{"id":"evt_1"}', null, "whsec_test"));
  const old = await stripeHeader('{"id":"evt_1"}', "whsec_test", now - 3600);
  assertFalse(await verifyStripeSignature('{"id":"evt_1"}', old, "whsec_test"));
});

Deno.test("stati Google Play: disdetto resta attivo fino a scadenza, in attesa non attiva nulla", () => {
  assertEquals(mapState("SUBSCRIPTION_STATE_ACTIVE"), "ACTIVE");
  assertEquals(mapState("SUBSCRIPTION_STATE_CANCELED"), "ACTIVE");
  assertEquals(mapState("SUBSCRIPTION_STATE_IN_GRACE_PERIOD"), "PAST_DUE");
  assertEquals(mapState("SUBSCRIPTION_STATE_ON_HOLD"), "EXPIRED");
  assertEquals(mapState("SUBSCRIPTION_STATE_EXPIRED"), "EXPIRED");
  assertEquals(mapState("SUBSCRIPTION_STATE_PENDING"), null);
});

Deno.test("l'impronta dell'utente coincide con quella calcolata dall'app (SHA-256 esadecimale)", async () => {
  assertEquals(
    await sha256Hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});

Deno.test("confronto dei segreti e base64url", () => {
  assert(safeEqual("segreto", "segreto"));
  assertFalse(safeEqual("segreto", "segret0"));
  assertFalse(safeEqual("segreto", "segreto-lungo"));
  const bytes = new Uint8Array([0, 250, 251, 252, 253, 254, 255]);
  assertEquals(base64UrlDecode(base64UrlEncode(bytes)), bytes);
});
