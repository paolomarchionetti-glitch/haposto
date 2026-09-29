// Google Play Developer API: stato degli abbonamenti HAPOSTO Plus.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { googleAccessToken, parseServiceAccount } from "./google.ts";
import { HttpError } from "./http.ts";

const PLAY_SCOPE = "https://www.googleapis.com/auth/androidpublisher";
export const PLUS_PLAN_CODE = "CONSUMER_PLUS";

export interface PlaySubscription {
  subscriptionState: string;
  linkedPurchaseToken?: string;
  acknowledgementState?: string;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  lineItems?: Array<{
    productId: string;
    expiryTime?: string;
    autoRenewingPlan?: { autoRenewEnabled?: boolean };
  }>;
  testPurchase?: Record<string, unknown>;
}

export function packageName(): string {
  return Deno.env.get("PLAY_PACKAGE_NAME") ?? "com.haposto";
}

async function playToken(): Promise<string> {
  const account = parseServiceAccount(Deno.env.get("PLAY_SERVICE_ACCOUNT"), "PLAY_SERVICE_ACCOUNT");
  return await googleAccessToken(account, PLAY_SCOPE);
}

/** Stato attuale dell'abbonamento chiesto direttamente a Google (mai fidarsi del telefono). */
export async function fetchSubscription(purchaseToken: string): Promise<PlaySubscription> {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName())}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  const response = await fetch(url, { headers: { Authorization: `Bearer ${await playToken()}` } });
  if (response.status === 404 || response.status === 410 || response.status === 400) {
    throw new HttpError(400, "PURCHASE_NOT_VALID");
  }
  if (!response.ok) {
    console.error("play api error", response.status, (await response.text()).slice(0, 300));
    throw new HttpError(502, "PLAY_API_ERROR");
  }
  return await response.json() as PlaySubscription;
}

/** Conferma a Google l'acquisto (entro 3 giorni, altrimenti Google lo rimborsa). */
export async function acknowledge(productId: string, purchaseToken: string): Promise<void> {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName())}/purchases/subscriptions/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
  const response = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${await playToken()}`, "Content-Type": "application/json" },
    body: "{}",
  });
  if (!response.ok && response.status !== 409) {
    console.error("play acknowledge error", response.status, (await response.text()).slice(0, 300));
    throw new HttpError(502, "PLAY_API_ERROR");
  }
}

/**
 * Stato Google → stato HAPOSTO. "CANCELED" su Google vuol dire "non si rinnova": resta attivo fino
 * alla scadenza. Periodo di tolleranza = PAST_DUE (Plus resta attivo); sospeso o scaduto = EXPIRED.
 * null = acquisto ancora in attesa di pagamento: non si attiva nulla.
 */
export function mapState(state: string): "ACTIVE" | "PAST_DUE" | "EXPIRED" | null {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
    case "SUBSCRIPTION_STATE_CANCELED":
      return "ACTIVE";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "PAST_DUE";
    case "SUBSCRIPTION_STATE_PENDING":
      return null;
    default:
      return "EXPIRED";
  }
}

/** Registra lo stato nel database (idempotente: la chiave è il purchaseToken). */
export async function applySubscription(
  db: SupabaseClient,
  userId: string,
  purchaseToken: string,
  subscription: PlaySubscription,
): Promise<{ status: string | null; validUntil: string | null }> {
  const status = mapState(subscription.subscriptionState);
  const item = subscription.lineItems?.[0];
  const validUntil = item?.expiryTime ?? null;
  if (status === null) return { status: null, validUntil };

  const { error } = await db.rpc("billing_upsert_consumer_subscription", {
    p_user_id: userId,
    p_plan_code: PLUS_PLAN_CODE,
    p_status: status,
    p_provider: "GOOGLE_PLAY",
    p_provider_purchase_ref: purchaseToken,
    p_current_period_end: validUntil,
    p_auto_renewing: item?.autoRenewingPlan?.autoRenewEnabled ?? false,
  });
  if (error) {
    console.error("billing_upsert_consumer_subscription", error.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }

  // Rinnovo con un nuovo token (cambio piano, riattivazione): il vecchio token non vale più.
  if (subscription.linkedPurchaseToken && subscription.linkedPurchaseToken !== purchaseToken) {
    await db.from("consumer_subscriptions")
      .update({ status: "CANCELED" })
      .eq("provider", "GOOGLE_PLAY")
      .eq("provider_purchase_ref", subscription.linkedPurchaseToken)
      .in("status", ["TRIALING", "ACTIVE", "PAST_DUE"]);
  }
  return { status, validUntil };
}

/** Utente già legato a un token (o al token precedente, per i rinnovi con token nuovo). */
export async function userForToken(db: SupabaseClient, tokens: Array<string | undefined>): Promise<string | null> {
  for (const token of tokens) {
    if (!token) continue;
    const { data } = await db.from("consumer_subscriptions")
      .select("user_id")
      .eq("provider", "GOOGLE_PLAY")
      .eq("provider_purchase_ref", token)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (data?.user_id) return data.user_id as string;
  }
  return null;
}
