// stripe-webhook — Stripe comunica pagamenti, rinnovi e disdette degli abbonamenti Pro.
// Deploy con --no-verify-jwt (Stripe non ha un token Supabase): l'autenticità si verifica con la
// firma. Segreti: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET.
// Eventi da attivare su Stripe: checkout.session.completed, customer.subscription.created,
// customer.subscription.updated, customer.subscription.deleted, invoice.paid, invoice.payment_failed.
import { HttpError, json, requireEnv, serve } from "../_shared/http.ts";
import { adminClient } from "../_shared/supabase.ts";
import { applyStripeSubscription, stripe, type StripeObject, verifyStripeSignature } from "../_shared/stripe.ts";

serve(async (request) => {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  const payload = await request.text();
  const valid = await verifyStripeSignature(
    payload,
    request.headers.get("Stripe-Signature"),
    requireEnv("STRIPE_WEBHOOK_SECRET"),
  );
  if (!valid) throw new HttpError(400, "INVALID_SIGNATURE");

  const event = JSON.parse(payload) as StripeObject;
  const db = adminClient();
  const { data: isNew, error: logError } = await db.rpc("billing_log_event", {
    p_provider: "STRIPE",
    p_event_id: event.id,
    p_event_type: event.type,
    p_payload: event,
  });
  if (logError) throw new HttpError(500, "DATABASE_ERROR");
  if (isNew === false) return json(request, 200, { ok: "duplicate" });

  try {
    await handle(db, event);
    await db.from("billing_events")
      .update({ processed_at: new Date().toISOString(), error: null })
      .eq("provider", "STRIPE")
      .eq("event_id", event.id);
    return json(request, 200, { ok: true });
  } catch (error) {
    // Tolto dal registro: Stripe riproverà e la ripetizione verrà elaborata.
    console.error("stripe event failed", event.type, error instanceof Error ? error.message : error);
    await db.from("billing_events").delete().eq("provider", "STRIPE").eq("event_id", event.id);
    throw error;
  }
});

async function handle(db: ReturnType<typeof adminClient>, event: StripeObject): Promise<void> {
  const object = event.data?.object ?? {};
  switch (event.type) {
    case "checkout.session.completed": {
      if (object.mode !== "subscription" || !object.subscription) return;
      const subscriptionId = typeof object.subscription === "string" ? object.subscription : object.subscription.id;
      await applyStripeSubscription(db, await stripe("GET", `subscriptions/${subscriptionId}`));
      return;
    }
    case "customer.subscription.created":
    case "customer.subscription.updated":
    case "customer.subscription.deleted":
      await applyStripeSubscription(db, object);
      return;
    case "invoice.paid":
    case "invoice.payment_failed":
      await recordInvoice(db, object, event.type === "invoice.paid" ? "SUCCEEDED" : "FAILED");
      return;
    default:
      return;
  }
}

/** Fattura Stripe → payments (serve all'elenco mensile per le fatture elettroniche). */
async function recordInvoice(db: ReturnType<typeof adminClient>, invoice: StripeObject, status: string): Promise<void> {
  const subscriptionRef = invoice.parent?.subscription_details?.subscription ?? invoice.subscription;
  if (!subscriptionRef) return; // non è una fattura di abbonamento
  let metadata = invoice.parent?.subscription_details?.metadata ?? invoice.subscription_details?.metadata ?? {};
  if (!metadata.restaurant_id) {
    const subscriptionId = typeof subscriptionRef === "string" ? subscriptionRef : subscriptionRef.id;
    metadata = (await stripe("GET", `subscriptions/${subscriptionId}`)).metadata ?? {};
  }
  const restaurantId = metadata.restaurant_id as string | undefined;
  if (!restaurantId) {
    console.error("invoice without restaurant", invoice.id);
    return;
  }
  const taxes = Array.isArray(invoice.total_taxes)
    ? invoice.total_taxes.reduce((sum: number, tax: StripeObject) => sum + (tax.amount ?? 0), 0)
    : invoice.tax ?? null;
  const paidAt = invoice.status_transitions?.paid_at;

  const { error } = await db.rpc("billing_record_payment", {
    p_payer_kind: "RESTAURANT",
    p_restaurant_id: restaurantId,
    p_user_id: metadata.user_id ?? null,
    p_provider: "STRIPE",
    p_provider_payment_id: invoice.id,
    p_plan_code: metadata.plan_code ?? "RESTAURANT_PRO",
    p_amount_cents: status === "SUCCEEDED" ? invoice.amount_paid ?? 0 : invoice.amount_due ?? 0,
    p_vat_cents: taxes,
    p_status: status,
    p_invoice_number: invoice.number ?? null,
    p_invoice_url: invoice.hosted_invoice_url ?? null,
    p_paid_at: typeof paidAt === "number" ? new Date(paidAt * 1000).toISOString() : null,
  });
  if (error) {
    console.error("billing_record_payment", error.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }
}
