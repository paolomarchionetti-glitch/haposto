// play-rtdn — notifiche in tempo reale di Google Play (rinnovi, disdette, rimborsi) via Pub/Sub.
// Endpoint push di Pub/Sub: https://<progetto>.supabase.co/functions/v1/play-rtdn?token=<PLAY_RTDN_TOKEN>
// Deploy con --no-verify-jwt. Il contenuto della notifica non è mai creduto: lo stato si richiede
// sempre a Google. Segreti: PLAY_RTDN_TOKEN, PLAY_SERVICE_ACCOUNT, PLAY_PACKAGE_NAME.
import { HttpError, json, requireEnv, safeEqual, serve } from "../_shared/http.ts";
import { adminClient } from "../_shared/supabase.ts";
import { applySubscription, fetchSubscription, packageName, userForToken } from "../_shared/play.ts";

interface DeveloperNotification {
  packageName?: string;
  subscriptionNotification?: { notificationType: number; purchaseToken: string; subscriptionId: string };
  voidedPurchaseNotification?: { purchaseToken: string; orderId: string };
  testNotification?: unknown;
}

serve(async (request) => {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  const token = new URL(request.url).searchParams.get("token") ?? "";
  if (!safeEqual(token, requireEnv("PLAY_RTDN_TOKEN"))) throw new HttpError(401, "UNAUTHORIZED");

  const envelope = await request.json().catch(() => null) as
    | { message?: { data?: string; messageId?: string; message_id?: string } }
    | null;
  const message = envelope?.message;
  if (!message?.data) return json(request, 200, { ignored: "no data" });

  let notification: DeveloperNotification;
  try {
    notification = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(message.data), (c) => c.charCodeAt(0))));
  } catch {
    return json(request, 200, { ignored: "unreadable" });
  }
  if (notification.testNotification) return json(request, 200, { ok: "test" });
  if (notification.packageName && notification.packageName !== packageName()) {
    return json(request, 200, { ignored: "other package" });
  }

  const purchaseToken = notification.subscriptionNotification?.purchaseToken ??
    notification.voidedPurchaseNotification?.purchaseToken;
  if (!purchaseToken) return json(request, 200, { ignored: "not a subscription" });

  const db = adminClient();
  const eventId = message.messageId ?? message.message_id ?? crypto.randomUUID();
  const eventType = notification.subscriptionNotification
    ? `SUBSCRIPTION_${notification.subscriptionNotification.notificationType}`
    : "VOIDED_PURCHASE";
  const { data: isNew, error: logError } = await db.rpc("billing_log_event", {
    p_provider: "GOOGLE_PLAY",
    p_event_id: eventId,
    p_event_type: eventType,
    p_payload: notification,
  });
  if (logError) throw new HttpError(500, "DATABASE_ERROR");
  if (isNew === false) return json(request, 200, { ok: "duplicate" });

  try {
    const subscription = await fetchSubscription(purchaseToken);
    const userId = await userForToken(db, [purchaseToken, subscription.linkedPurchaseToken]);
    // Acquisto non ancora verificato dall'app: lo registrerà play-verify al primo avvio.
    if (userId) await applySubscription(db, userId, purchaseToken, subscription);
    await markEvent(db, eventId, null);
    return json(request, 200, { ok: true, linked: userId !== null });
  } catch (error) {
    // Evento tolto dal registro e risposta d'errore: Pub/Sub ripeterà la consegna più tardi e
    // la ripetizione non verrà scambiata per un doppione.
    console.error("rtdn processing failed", error instanceof Error ? error.message : error);
    await db.from("billing_events").delete().eq("provider", "GOOGLE_PLAY").eq("event_id", eventId);
    throw error;
  }
});

async function markEvent(db: ReturnType<typeof adminClient>, eventId: string, error: string | null) {
  await db.from("billing_events")
    .update({ processed_at: new Date().toISOString(), error })
    .eq("provider", "GOOGLE_PLAY")
    .eq("event_id", eventId);
}
