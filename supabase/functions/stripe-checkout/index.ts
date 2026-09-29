// stripe-checkout — il titolare (sul sito, con Google + verifica in due passaggi) attiva Pro.
// Crea la pagina di pagamento Stripe legata al locale e restituisce l'indirizzo a cui andare.
// Segreti: STRIPE_SECRET_KEY, HAPOSTO_SITE_URL, facoltativi STRIPE_PRICE_PRO_MONTH,
// STRIPE_PRICE_PRO_YEAR (altrimenti dalla tabella plans) e STRIPE_TAX_RATE_ID (IVA 22%).
import { HttpError, json, serve } from "../_shared/http.ts";
import { adminClient, requireCaller } from "../_shared/supabase.ts";
import { requireOwner } from "../_shared/owner.ts";
import { customerForRestaurant, siteUrl, stripe } from "../_shared/stripe.ts";

const PLAN_CODE = "RESTAURANT_PRO";

serve(async (request) => {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  const caller = await requireCaller(request);
  const body = await request.json().catch(() => ({})) as { restaurantId?: string; interval?: string };
  const interval = body.interval === "YEAR" ? "YEAR" : "MONTH";
  const restaurant = await requireOwner(caller, body.restaurantId);

  if (restaurant.plan_source === "STRIPE" && restaurant.plan_code !== "RESTAURANT_BASIC") {
    throw new HttpError(409, "ALREADY_SUBSCRIBED");
  }

  // Dati di fatturazione salvati dal titolare (tabella protetta da RLS + 2FA).
  const { data: billing, error: billingError } = await caller.asUser
    .from("restaurant_billing_profiles")
    .select("*")
    .eq("restaurant_id", restaurant.restaurant_id)
    .maybeSingle();
  if (billingError) throw new HttpError(403, "MFA_REQUIRED");
  if (!billing) throw new HttpError(400, "BILLING_PROFILE_REQUIRED");

  const db = adminClient();
  const { data: plan } = await db.from("plans")
    .select("stripe_price_month, stripe_price_year")
    .eq("code", PLAN_CODE)
    .maybeSingle();
  const price = interval === "YEAR"
    ? Deno.env.get("STRIPE_PRICE_PRO_YEAR") ?? plan?.stripe_price_year
    : Deno.env.get("STRIPE_PRICE_PRO_MONTH") ?? plan?.stripe_price_month;
  if (!price) throw new HttpError(500, "NOT_CONFIGURED");

  let customer = await customerForRestaurant(db, restaurant.restaurant_id);
  const customerData = {
    name: billing.legal_name,
    email: billing.invoice_email ?? caller.user.email,
    preferred_locales: ["it"],
    address: {
      line1: billing.billing_address,
      city: billing.billing_city,
      postal_code: billing.billing_postal_code,
      state: billing.billing_province,
      country: billing.country ?? "IT",
    },
    metadata: {
      restaurant_id: restaurant.restaurant_id,
      vat_number: billing.vat_number ?? "",
      tax_code: billing.tax_code ?? "",
      sdi_code: billing.sdi_code ?? "",
      pec_email: billing.pec_email ?? "",
    },
  };
  if (customer) {
    await stripe("POST", `customers/${customer}`, customerData);
  } else {
    const created = await stripe("POST", "customers", {
      ...customerData,
      tax_id_data: billing.vat_number ? [{ type: "eu_vat", value: `IT${billing.vat_number}` }] : undefined,
    });
    customer = created.id as string;
  }

  const taxRate = Deno.env.get("STRIPE_TAX_RATE_ID");
  const site = siteUrl();
  const session = await stripe("POST", "checkout/sessions", {
    mode: "subscription",
    customer,
    client_reference_id: restaurant.restaurant_id,
    locale: "it",
    allow_promotion_codes: true,
    line_items: [{ price, quantity: 1, tax_rates: taxRate ? [taxRate] : undefined }],
    metadata: { restaurant_id: restaurant.restaurant_id, user_id: caller.user.id },
    subscription_data: {
      metadata: { restaurant_id: restaurant.restaurant_id, plan_code: PLAN_CODE, user_id: caller.user.id },
    },
    success_url: `${site}/ristoratori/?esito=ok`,
    cancel_url: `${site}/ristoratori/?esito=annullato`,
  });
  return json(request, 200, { url: session.url });
});
