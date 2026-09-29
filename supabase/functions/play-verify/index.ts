// play-verify — l'app manda il purchaseToken dopo un acquisto (o un ripristino) di HAPOSTO Plus.
// La funzione chiede lo stato a Google, controlla che l'acquisto sia di questo utente, attiva Plus
// e conferma l'acquisto a Google. Richiede la sessione dell'utente (deploy normale, con JWT).
// Segreti: PLAY_SERVICE_ACCOUNT (JSON), PLAY_PACKAGE_NAME (es. com.haposto).
import { HttpError, json, serve, sha256Hex } from "../_shared/http.ts";
import { adminClient, requireCaller } from "../_shared/supabase.ts";
import { acknowledge, applySubscription, fetchSubscription, userForToken } from "../_shared/play.ts";

const PRODUCT_ID = "haposto_plus";

serve(async (request) => {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  const caller = await requireCaller(request);
  const body = await request.json().catch(() => ({})) as { productId?: string; purchaseToken?: string };
  const purchaseToken = (body.purchaseToken ?? "").trim();
  if (body.productId !== PRODUCT_ID || purchaseToken.length < 10 || purchaseToken.length > 4096) {
    throw new HttpError(400, "PURCHASE_NOT_VALID");
  }

  const subscription = await fetchSubscription(purchaseToken);
  const item = subscription.lineItems?.find((line) => line.productId === PRODUCT_ID);
  if (!item) throw new HttpError(400, "PURCHASE_NOT_VALID");

  // L'app passa a Google l'impronta SHA-256 dell'id utente: l'acquisto deve essere suo.
  const expected = await sha256Hex(caller.user.id);
  const owner = subscription.externalAccountIdentifiers?.obfuscatedExternalAccountId;
  if (owner !== expected) throw new HttpError(403, "PURCHASE_OTHER_ACCOUNT");

  const db = adminClient();
  const linkedUser = await userForToken(db, [purchaseToken]);
  if (linkedUser && linkedUser !== caller.user.id) throw new HttpError(403, "PURCHASE_OTHER_ACCOUNT");

  const result = await applySubscription(db, caller.user.id, purchaseToken, subscription);
  if (result.status === null) return json(request, 202, { status: "PENDING" });

  if (subscription.acknowledgementState !== "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED" && result.status !== "EXPIRED") {
    await acknowledge(PRODUCT_ID, purchaseToken);
  }
  return json(request, 200, { status: result.status, valid_until: result.validUntil });
});
