// Accesso alle API Google (Firebase Cloud Messaging, Google Play) con un account di servizio.
// Nessuna libreria esterna: il token OAuth si ottiene firmando un JWT con Web Crypto.
import { base64UrlEncode, HttpError } from "./http.ts";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id?: string;
  token_uri?: string;
}

export function parseServiceAccount(raw: string | undefined, secretName: string): ServiceAccount {
  if (!raw) {
    console.error(`missing secret ${secretName}`);
    throw new HttpError(500, "NOT_CONFIGURED");
  }
  try {
    const parsed = JSON.parse(raw) as ServiceAccount;
    if (!parsed.client_email || !parsed.private_key) throw new Error("incomplete");
    return parsed;
  } catch {
    console.error(`secret ${secretName} is not a service account JSON`);
    throw new HttpError(500, "NOT_CONFIGURED");
  }
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

const tokenCache = new Map<string, { token: string; expiresAt: number }>();

/** Token OAuth di breve durata per [scope], riutilizzato finché valido. */
export async function googleAccessToken(account: ServiceAccount, scope: string): Promise<string> {
  const cacheKey = `${account.client_email}|${scope}`;
  const cached = tokenCache.get(cacheKey);
  if (cached && cached.expiresAt > Date.now() + 60_000) return cached.token;

  const tokenUri = account.token_uri ?? "https://oauth2.googleapis.com/token";
  const now = Math.floor(Date.now() / 1000);
  const encoder = new TextEncoder();
  const header = base64UrlEncode(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64UrlEncode(encoder.encode(JSON.stringify({
    iss: account.client_email,
    scope,
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = `${header}.${claims}`;
  const key = await importPrivateKey(account.private_key);
  const signature = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(unsigned)));
  const assertion = `${unsigned}.${base64UrlEncode(signature)}`;

  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    console.error("google token error", response.status, await response.text());
    throw new HttpError(502, "GOOGLE_AUTH_FAILED");
  }
  const body = await response.json() as { access_token: string; expires_in: number };
  tokenCache.set(cacheKey, { token: body.access_token, expiresAt: Date.now() + body.expires_in * 1000 });
  return body.access_token;
}
