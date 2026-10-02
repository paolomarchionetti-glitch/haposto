// Client Supabase per le Edge Function: uno con i permessi del server, uno "come l'utente".
import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";
import { base64UrlDecode, HttpError, requireEnv } from "./http.ts";

/**
 * Chiave del progetto, in quest'ordine: segreto HAPOSTO_… messo a mano (resta valido); chiave
 * "default" delle chiavi nuove, che Supabase fornisce da sé come JSON (i progetti creati da
 * novembre 2025 hanno solo queste); chiave legacy.
 */
function projectKey(manual: string, keySet: string, legacy: string): string {
  const own = Deno.env.get(manual);
  if (own) return own;
  try {
    const key = JSON.parse(Deno.env.get(keySet) ?? "{}")?.default;
    if (typeof key === "string" && key) return key;
  } catch {
    // JSON non leggibile: si passa alla chiave legacy.
  }
  return requireEnv(legacy);
}

export function serverKey(): string {
  return projectKey("HAPOSTO_SECRET_KEY", "SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY");
}

export function publicKey(): string {
  return projectKey("HAPOSTO_PUBLISHABLE_KEY", "SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY");
}

/** Accesso completo al database: solo per il codice del server, mai per dati scelti dall'utente. */
export function adminClient(): SupabaseClient {
  return createClient(requireEnv("SUPABASE_URL"), serverKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export interface Caller {
  user: User;
  /** Livello di autenticazione della sessione: "aal2" = verifica in due passaggi fatta. */
  aal: string;
  /** Client che agisce con i permessi (e le regole RLS) dell'utente. */
  asUser: SupabaseClient;
}

/** Legge e verifica l'utente dalla richiesta (token di sessione Supabase). */
export async function requireCaller(request: Request): Promise<Caller> {
  const header = request.headers.get("Authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  if (!token) throw new HttpError(401, "AUTH_REQUIRED");

  const { data, error } = await adminClient().auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "AUTH_REQUIRED");

  // Il token è appena stato verificato dal server di autenticazione: si legge solo il livello.
  let aal = "aal1";
  try {
    const payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(token.split(".")[1] ?? "")));
    if (typeof payload.aal === "string") aal = payload.aal;
  } catch {
    // Token non leggibile: resta aal1.
  }

  const asUser = createClient(requireEnv("SUPABASE_URL"), publicKey(), {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return { user: data.user, aal, asUser };
}

/** Errori SQL come "MFA_REQUIRED" o "OWNER_REQUIRED" diventano codici per l'app. */
export function sqlErrorCode(message: string | undefined): string {
  const known = [
    "MFA_REQUIRED",
    "ACCOUNT_BLOCKED",
    "OWNER_REQUIRED",
    "RESTAURANT_SUSPENDED",
    "AUTH_REQUIRED",
    "Not authorized",
  ];
  const found = known.find((code) => (message ?? "").includes(code));
  return found === "Not authorized" ? "NOT_AUTHORIZED" : found ?? "DATABASE_ERROR";
}
