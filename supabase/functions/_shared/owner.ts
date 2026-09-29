// Controllo comune a checkout e portale: solo il titolare, con verifica in due passaggi.
import { HttpError } from "./http.ts";
import { type Caller, sqlErrorCode } from "./supabase.ts";

export interface OwnedRestaurant {
  restaurant_id: string;
  name: string;
  partnership_status: string;
  my_role: string;
  plan_code: string;
  plan_source: string | null;
  plan_valid_until: string | null;
  mfa_required: boolean;
  mfa_ok: boolean;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function requireOwner(caller: Caller, restaurantId: unknown): Promise<OwnedRestaurant> {
  if (typeof restaurantId !== "string" || !UUID.test(restaurantId)) {
    throw new HttpError(400, "RESTAURANT_NOT_FOUND");
  }
  // La funzione SQL applica le stesse regole dell'app (account sospeso, ruolo, 2FA).
  const { data, error } = await caller.asUser.rpc("restaurant_manager_info", { p_restaurant_id: restaurantId });
  if (error) throw new HttpError(403, sqlErrorCode(error.message));
  const info = (Array.isArray(data) ? data[0] : data) as OwnedRestaurant | undefined;
  if (!info) throw new HttpError(404, "RESTAURANT_NOT_FOUND");
  if (info.my_role !== "OWNER") throw new HttpError(403, "OWNER_REQUIRED");
  if (info.mfa_required && !info.mfa_ok) throw new HttpError(403, "MFA_REQUIRED");
  if (info.partnership_status !== "ACTIVE_PARTNER") throw new HttpError(403, "RESTAURANT_NOT_ACTIVE");
  return info;
}
