// push-dispatch — invia le notifiche in coda (notification_outbox) con Firebase Cloud Messaging.
//
// Chiamata ogni minuto da pg_cron (supabase/ops/push_dispatch_cron.sql) con l'intestazione
// "x-haposto-cron" uguale al segreto HAPOSTO_CRON_SECRET. Deploy con --no-verify-jwt.
// Segreti: HAPOSTO_CRON_SECRET, FIREBASE_SERVICE_ACCOUNT (JSON dell'account di servizio Firebase).
import { HttpError, json, requireEnv, safeEqual, serve } from "../_shared/http.ts";
import { googleAccessToken, parseServiceAccount } from "../_shared/google.ts";
import { adminClient } from "../_shared/supabase.ts";

interface QueuedNotification {
  notification_id: number;
  user_id: string;
  kind: string;
  restaurant_id: string | null;
  title: string;
  body: string;
  data: Record<string, unknown> | null;
  tokens: string[];
}

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

serve(async (request) => {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  const secret = requireEnv("HAPOSTO_CRON_SECRET");
  if (!safeEqual(request.headers.get("x-haposto-cron") ?? "", secret)) {
    throw new HttpError(401, "UNAUTHORIZED");
  }

  const account = parseServiceAccount(Deno.env.get("FIREBASE_SERVICE_ACCOUNT"), "FIREBASE_SERVICE_ACCOUNT");
  const projectId = account.project_id ?? requireEnv("FIREBASE_PROJECT_ID");
  const db = adminClient();

  const { data, error } = await db.rpc("claim_notification_batch", { p_limit: 200 });
  if (error) {
    console.error("claim_notification_batch", error.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }
  const batch = (data ?? []) as QueuedNotification[];
  if (batch.length === 0) return json(request, 200, { delivered: 0, no_device: 0, failed: 0 });

  const accessToken = await googleAccessToken(account, FCM_SCOPE);
  const sentIds: number[] = [];
  const failedIds: number[] = [];
  const invalidTokens: string[] = [];
  let lastError: string | null = null;
  // Solo per la diagnosi (risposta visibile in net._http_response): arrivate a un telefono /
  // chiuse perché l'utente non ha nessun telefono registrato (accesso all'app mai fatto).
  let delivered = 0;
  let noDevice = 0;

  for (const item of batch) {
    if (item.tokens.length === 0) {
      // Nessun telefono registrato: niente da inviare, la notifica si chiude.
      sentIds.push(item.notification_id);
      noDevice++;
      continue;
    }
    let reached = false;
    for (const token of item.tokens) {
      const result = await sendToDevice(projectId, accessToken, token, item);
      if (result === "OK") reached = true;
      else if (result === "INVALID_TOKEN") invalidTokens.push(token);
      else lastError = result;
    }
    // Se almeno un telefono l'ha ricevuta è inviata; se tutti i token erano scaduti, pure
    // (riprovare non servirebbe). Si ritenta solo per errori temporanei.
    const onlyInvalid = item.tokens.every((token) => invalidTokens.includes(token));
    if (reached || onlyInvalid) sentIds.push(item.notification_id);
    else failedIds.push(item.notification_id);
    if (reached) delivered++;
    else if (onlyInvalid) noDevice++;
  }

  const { error: completeError } = await db.rpc("complete_notifications", {
    p_sent_ids: sentIds,
    p_failed_ids: failedIds,
    p_error: lastError,
    p_invalid_tokens: invalidTokens,
  });
  if (completeError) {
    console.error("complete_notifications", completeError.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }
  return json(request, 200, {
    delivered,
    no_device: noDevice,
    failed: failedIds.length,
    invalid_tokens: invalidTokens.length,
  });
});

/** Messaggio "data": titolo, testo e tasti li costruisce l'app (canali e azioni rapide). */
async function sendToDevice(
  projectId: string,
  accessToken: string,
  token: string,
  item: QueuedNotification,
): Promise<"OK" | "INVALID_TOKEN" | string> {
  const extra = item.data ?? {};
  const data: Record<string, string> = {
    kind: item.kind,
    title: item.title,
    body: item.body,
  };
  if (item.restaurant_id) data.restaurant_id = item.restaurant_id;
  for (const [key, value] of Object.entries(extra)) {
    if (value !== null && value !== undefined && !(key in data)) data[key] = String(value);
  }

  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token,
        data,
        android: {
          priority: "high",
          // Una notifica "vecchia" di disponibilità non serve più: scade dopo 30 minuti.
          ttl: "1800s",
        },
      },
    }),
  });
  if (response.ok) return "OK";

  const text = await response.text();
  if (response.status === 404 || text.includes("UNREGISTERED") ||
    (response.status === 400 && text.includes("registration token"))) {
    return "INVALID_TOKEN";
  }
  console.error("fcm error", response.status, text.slice(0, 300));
  return `FCM_${response.status}`;
}
