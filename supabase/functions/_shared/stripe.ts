// Stripe via API REST (nessuna libreria): abbonamenti Pro dei ristoranti.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError, requireEnv, safeEqual } from "./http.ts";

type FormValue = string | number | boolean | null | undefined | FormObject | FormValue[];
interface FormObject {
  [key: string]: FormValue;
}

/** Codifica "a[b][0][c]=…" come vuole Stripe. */
function encodeForm(params: FormObject, prefix = "", out = new URLSearchParams()): URLSearchParams {
  for (const [key, value] of Object.entries(params)) {
    const name = prefix ? `${prefix}[${key}]` : key;
    if (value === null || value === undefined) continue;
    if (Array.isArray(value)) {
      value.forEach((entry, index) => {
        if (entry !== null && typeof entry === "object" && !Array.isArray(entry)) {
          encodeForm(entry as FormObject, `${name}[${index}]`, out);
        } else if (entry !== null && entry !== undefined) {
          out.append(`${name}[${index}]`, String(entry));
        }
      });
    } else if (typeof value === "object") {
      encodeForm(value as FormObject, name, out);
    } else {
      out.append(name, String(value));
    }
  }
  return out;
}

// deno-lint-ignore no-explicit-any
export type StripeObject = Record<string, any>;

export async function stripe(method: "GET" | "POST", path: string, params: FormObject = {}): Promise<StripeObject> {
  const key = requireEnv("STRIPE_SECRET_KEY");
  const query = method === "GET" && Object.keys(params).length > 0 ? `?${encodeForm(params)}` : "";
  const response = await fetch(`https://api.stripe.com/v1/${path}${query}`, {
    method,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: method === "POST" ? encodeForm(params) : undefined,
  });
  const body = await response.json() as StripeObject;
  if (!response.ok) {
    console.error("stripe error", response.status, body?.error?.type, body?.error?.message);
    throw new HttpError(502, "STRIPE_ERROR");
  }
  return body;
}

/** Verifica la firma "Stripe-Signature" del webhook (HMAC-SHA256, tolleranza 5 minuti). */
export async function verifyStripeSignature(payload: string, header: string | null, secret: string): Promise<boolean> {
  if (!header) return false;
  const parts = header.split(",").map((part) => part.trim().split("="));
  const timestamp = parts.find(([k]) => k === "t")?.[1];
  const signatures = parts.filter(([k]) => k === "v1").map(([, v]) => v ?? "");
  if (!timestamp || signatures.length === 0) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${timestamp}.${payload}`)));
  const expected = [...mac].map((b) => b.toString(16).padStart(2, "0")).join("");
  return signatures.some((signature) => safeEqual(signature, expected));
}

const STATUS: Record<string, string | null> = {
  trialing: "TRIALING",
  active: "ACTIVE",
  past_due: "PAST_DUE",
  unpaid: "PAST_DUE",
  canceled: "CANCELED",
  incomplete: null, // primo pagamento non ancora riuscito: non si attiva nulla
  incomplete_expired: "EXPIRED",
  paused: "EXPIRED",
};

function toIso(seconds: unknown): string | null {
  return typeof seconds === "number" ? new Date(seconds * 1000).toISOString() : null;
}

/** Abbonamento Stripe → restaurant_subscriptions (idempotente sull'id dell'abbonamento). */
export async function applyStripeSubscription(db: SupabaseClient, subscription: StripeObject): Promise<string | null> {
  const restaurantId = subscription.metadata?.restaurant_id as string | undefined;
  if (!restaurantId) {
    console.error("subscription without restaurant_id", subscription.id);
    return null;
  }
  const status = STATUS[subscription.status as string];
  if (!status) return null;

  const item = subscription.items?.data?.[0] ?? {};
  const interval = item.price?.recurring?.interval === "year" ? "YEAR" : "MONTH";
  // Dalle versioni API 2025 i periodi stanno sulle voci dell'abbonamento.
  const periodStart = toIso(subscription.current_period_start ?? item.current_period_start);
  const periodEnd = toIso(subscription.current_period_end ?? item.current_period_end);
  const customer = typeof subscription.customer === "string" ? subscription.customer : subscription.customer?.id;

  const { error } = await db.rpc("billing_upsert_restaurant_subscription", {
    p_restaurant_id: restaurantId,
    p_plan_code: subscription.metadata?.plan_code ?? "RESTAURANT_PRO",
    p_status: status,
    p_billing_interval: interval,
    p_provider: "STRIPE",
    p_provider_customer_id: customer ?? null,
    p_provider_subscription_id: subscription.id,
    p_current_period_start: periodStart,
    p_current_period_end: periodEnd,
    p_cancel_at_period_end: Boolean(subscription.cancel_at_period_end),
  });
  if (error) {
    console.error("billing_upsert_restaurant_subscription", error.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }
  return restaurantId;
}

/** Cliente Stripe già associato al locale (pagamenti precedenti), se esiste. */
export async function customerForRestaurant(db: SupabaseClient, restaurantId: string): Promise<string | null> {
  const { data } = await db.from("restaurant_subscriptions")
    .select("provider_customer_id")
    .eq("restaurant_id", restaurantId)
    .eq("provider", "STRIPE")
    .not("provider_customer_id", "is", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  return (data?.provider_customer_id as string | undefined) ?? null;
}

export function siteUrl(): string {
  return (Deno.env.get("HAPOSTO_SITE_URL") ?? "https://haposto.app").replace(/\/+$/, "");
}
