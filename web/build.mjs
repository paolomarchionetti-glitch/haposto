#!/usr/bin/env node
// Costruisce il sito statico di HAPOSTO in web/dist (nessuna dipendenza: basta Node 18+).
//
//   node web/build.mjs
//
// Variabili (facoltative; in GitHub Actions arrivano dalle "Variables" del repository):
//   HAPOSTO_SITE_URL                 es. https://haposto.app (default)
//   HAPOSTO_SUPABASE_URL             indirizzo del progetto Supabase di PRODUZIONE
//   HAPOSTO_SUPABASE_PUBLISHABLE_KEY chiave pubblica (publishable / anon), MAI la secret key
//   HAPOSTO_PLAY_URL                 link alla scheda Google Play
//   HAPOSTO_CONTACT_EMAIL            email di assistenza mostrata nelle pagine
//   HAPOSTO_ANDROID_CERT_SHA256      impronte SHA-256 del certificato di firma (separate da virgola)
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { escapeHtml, markdownToHtml } from "./markdown.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const src = join(here, "src");
const dist = join(here, "dist");
const legalDir = join(here, "..", "app", "src", "main", "assets", "legal");

const env = (name, fallback = "") => (process.env[name] ?? "").trim() || fallback;
const siteUrl = env("HAPOSTO_SITE_URL", "https://haposto.app").replace(/\/+$/, "");
const supabaseUrl = env("HAPOSTO_SUPABASE_URL");
const supabaseKey = env("HAPOSTO_SUPABASE_PUBLISHABLE_KEY");

if (supabaseKey.startsWith("sb_secret_") || supabaseKey.includes("service_role")) {
  console.error("ERRORE: HAPOSTO_SUPABASE_PUBLISHABLE_KEY deve essere la chiave PUBBLICA, non quella segreta.");
  process.exit(1);
}

rmSync(dist, { recursive: true, force: true });
mkdirSync(dist, { recursive: true });
cpSync(src, dist, { recursive: true });

// 1) Configurazione pubblica letta dalle pagine.
const config = {
  siteUrl,
  supabaseUrl,
  supabaseKey,
  playUrl: env("HAPOSTO_PLAY_URL"),
  contactEmail: env("HAPOSTO_CONTACT_EMAIL", "info@haposto.app"),
};
writeFileSync(
  join(dist, "assets", "config.js"),
  `// Generato da web/build.mjs: solo valori pubblici.\nwindow.HAPOSTO_CONFIG = ${JSON.stringify(config, null, 2)};\n`,
);

// 2) Pagine legali dagli stessi file Markdown mostrati nell'app.
const template = readFileSync(join(here, "templates", "legal.html"), "utf8");
const legalPages = {
  "privacy.md": "privacy",
  "termini.md": "termini",
  "termini-ristoranti.md": "termini-ristoranti",
  "cookie.md": "cookie",
  "licenze.md": "licenze",
};
for (const file of readdirSync(legalDir)) {
  const slug = legalPages[file];
  if (!slug) continue;
  const markdown = readFileSync(join(legalDir, file), "utf8");
  const title = (markdown.match(/^#\s+(.+)$/m)?.[1] ?? slug).trim();
  const html = template
    .replaceAll("{{title}}", escapeHtml(title))
    .replaceAll("{{source}}", escapeHtml(file))
    .replace("{{content}}", markdownToHtml(markdown));
  mkdirSync(join(dist, slug), { recursive: true });
  writeFileSync(join(dist, slug, "index.html"), html);
}

// 3) Digital Asset Links (facoltativo): dichiara che l'app com.haposto appartiene al sito,
//    base per aprire in futuro i link /r/... direttamente nell'app.
const fingerprints = env("HAPOSTO_ANDROID_CERT_SHA256").split(",").map((v) => v.trim()).filter(Boolean);
if (fingerprints.length > 0) {
  mkdirSync(join(dist, ".well-known"), { recursive: true });
  writeFileSync(
    join(dist, ".well-known", "assetlinks.json"),
    JSON.stringify([{
      relation: ["delegate_permission/common.handle_all_urls"],
      target: { namespace: "android_app", package_name: "com.haposto", sha256_cert_fingerprints: fingerprints },
    }], null, 2),
  );
}

// GitHub Pages: niente elaborazione Jekyll (serve la cartella .well-known).
writeFileSync(join(dist, ".nojekyll"), "");
if (!existsSync(join(dist, "404.html"))) throw new Error("manca 404.html");

console.log(`Sito pronto in ${dist}`);
console.log(`  indirizzo: ${siteUrl}`);
console.log(`  Supabase:  ${supabaseUrl ? supabaseUrl : "NON configurato (area ristoratori e pagine /r/ disattivate)"}`);
