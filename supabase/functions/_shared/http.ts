// Utilità comuni alle Edge Function HAPOSTO (Deno).

/** Origini del sito autorizzate a chiamare le funzioni dal browser (checkout, portale). */
function allowedOrigins(): string[] {
  const configured = Deno.env.get("HAPOSTO_ALLOWED_ORIGINS") ?? Deno.env.get("HAPOSTO_SITE_URL") ?? "";
  return configured
    .split(",")
    .map((value) => value.trim().replace(/\/+$/, ""))
    .filter((value) => value.length > 0);
}

export function corsHeaders(request: Request): Record<string, string> {
  const origin = request.headers.get("Origin") ?? "";
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
  if (origin && allowedOrigins().includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

export function json(request: Request, status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(request) },
  });
}

/** Errore con codice stabile: l'app e il sito lo traducono in un messaggio in italiano. */
export class HttpError extends Error {
  constructor(readonly status: number, readonly code: string) {
    super(code);
  }
}

/** Esegue il gestore rispondendo sempre in JSON, senza mai esporre dettagli interni. */
export function serve(handler: (request: Request) => Promise<Response>): void {
  Deno.serve(async (request) => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders(request) });
    }
    try {
      return await handler(request);
    } catch (error) {
      if (error instanceof HttpError) {
        return json(request, error.status, { error: error.code });
      }
      console.error("unexpected error", error);
      return json(request, 500, { error: "INTERNAL_ERROR" });
    }
  });
}

export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    console.error(`missing secret ${name}`);
    throw new HttpError(500, "NOT_CONFIGURED");
  }
  return value;
}

/** Confronto a tempo costante per segreti condivisi (cron, Pub/Sub). */
export function safeEqual(a: string, b: string): boolean {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  let diff = left.length ^ right.length;
  for (let i = 0; i < Math.max(left.length, right.length); i++) {
    diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return diff === 0;
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function base64UrlDecode(value: string): Uint8Array {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "=");
  const binary = atob(padded);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

export function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
