// billing-portal — il titolare cambia carta, scarica le fatture o disdice Pro sul portale Stripe.
// Segreti: STRIPE_SECRET_KEY, HAPOSTO_SITE_URL.
import { HttpError, json, serve } from "../_shared/http.ts";
import { adminClient, requireCaller } from "../_shared/supabase.ts";
import { requireOwner } from "../_shared/owner.ts";
import { customerForRestaurant, siteUrl, stripe } from "../_shared/stripe.ts";

serve(async (request) => {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  const caller = await requireCaller(request);
  const body = await request.json().catch(() => ({})) as { restaurantId?: string };
  const restaurant = await requireOwner(caller, body.restaurantId);

  const customer = await customerForRestaurant(adminClient(), restaurant.restaurant_id);
  if (!customer) throw new HttpError(404, "NO_STRIPE_CUSTOMER");

  const session = await stripe("POST", "billing_portal/sessions", {
    customer,
    locale: "it",
    return_url: `${siteUrl()}/ristoratori/`,
  });
  return json(request, 200, { url: session.url });
});
