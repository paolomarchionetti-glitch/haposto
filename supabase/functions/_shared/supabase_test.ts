// Test delle chiavi con cui le Edge Function parlano al database: `deno test --allow-env`.
import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { HttpError } from "./http.ts";
import { publicKey, serverKey } from "./supabase.ts";

const KEY_VARIABLES = [
  "HAPOSTO_SECRET_KEY",
  "HAPOSTO_PUBLISHABLE_KEY",
  "SUPABASE_SECRET_KEYS",
  "SUPABASE_PUBLISHABLE_KEYS",
  "SUPABASE_SERVICE_ROLE_KEY",
  "SUPABASE_ANON_KEY",
];

/** Esegue il controllo con solo le variabili indicate, poi rimette quelle di prima. */
function withKeys(values: Record<string, string>, check: () => void) {
  const saved = new Map(KEY_VARIABLES.map((name) => [name, Deno.env.get(name)]));
  for (const name of KEY_VARIABLES) Deno.env.delete(name);
  for (const [name, value] of Object.entries(values)) Deno.env.set(name, value);
  try {
    check();
  } finally {
    for (const [name, value] of saved) {
      if (value === undefined) Deno.env.delete(name);
      else Deno.env.set(name, value);
    }
  }
}

Deno.test("progetto nuovo, senza chiavi legacy: si usano le chiavi 'default' fornite da Supabase", () => {
  withKeys({
    SUPABASE_SECRET_KEYS: '{"default":"sb_secret_nuova"}',
    SUPABASE_PUBLISHABLE_KEYS: '{"default":"sb_publishable_nuova"}',
  }, () => {
    assertEquals(serverKey(), "sb_secret_nuova");
    assertEquals(publicKey(), "sb_publishable_nuova");
  });
});

Deno.test("le chiavi nuove valgono più di quelle legacy; un segreto HAPOSTO_ messo a mano più di tutte", () => {
  const both = {
    SUPABASE_SECRET_KEYS: '{"default":"sb_secret_nuova"}',
    SUPABASE_PUBLISHABLE_KEYS: '{"default":"sb_publishable_nuova"}',
    SUPABASE_SERVICE_ROLE_KEY: "eyJ.legacy.service",
    SUPABASE_ANON_KEY: "eyJ.legacy.anon",
  };
  withKeys(both, () => {
    assertEquals(serverKey(), "sb_secret_nuova");
    assertEquals(publicKey(), "sb_publishable_nuova");
  });
  withKeys(
    { ...both, HAPOSTO_SECRET_KEY: "sb_secret_a_mano", HAPOSTO_PUBLISHABLE_KEY: "sb_publishable_a_mano" },
    () => {
      assertEquals(serverKey(), "sb_secret_a_mano");
      assertEquals(publicKey(), "sb_publishable_a_mano");
    },
  );
});

Deno.test("progetto vecchio (solo chiavi legacy) o JSON senza 'default': restano le chiavi legacy", () => {
  withKeys({ SUPABASE_SERVICE_ROLE_KEY: "eyJ.legacy.service", SUPABASE_ANON_KEY: "eyJ.legacy.anon" }, () => {
    assertEquals(serverKey(), "eyJ.legacy.service");
    assertEquals(publicKey(), "eyJ.legacy.anon");
  });
  withKeys({
    SUPABASE_SECRET_KEYS: '{"altra":"sb_secret_altra"}',
    SUPABASE_PUBLISHABLE_KEYS: "non è JSON",
    SUPABASE_SERVICE_ROLE_KEY: "eyJ.legacy.service",
    SUPABASE_ANON_KEY: "eyJ.legacy.anon",
  }, () => {
    assertEquals(serverKey(), "eyJ.legacy.service");
    assertEquals(publicKey(), "eyJ.legacy.anon");
  });
});

Deno.test("senza nessuna chiave la funzione risponde NOT_CONFIGURED", () => {
  withKeys({}, () => {
    assertThrows(() => serverKey(), HttpError, "NOT_CONFIGURED");
    assertThrows(() => publicKey(), HttpError, "NOT_CONFIGURED");
  });
});
