#!/usr/bin/env node
// Controlla i documenti di docs/ (nessuna dipendenza: basta Node 18+ e git).
//
//   node .github/scripts/check_docs.mjs
//
// 1) Nomi: ogni documento sta in una cartella a tema e si chiama AAAA-MM-GG_NOME.md (data
//    dell'ultimo aggiornamento); il registro docs/modifiche/ usa AAAA-MM-GG_prNN-titolo-breve.md.
// 2) Riferimenti: in tutti i file del repository i percorsi docs/... esistono e i documenti non
//    sono citati con un nome vecchio (senza data o con una data superata).
// 3) Link: i link relativi dei file Markdown portano a un file o a una cartella esistente.
// 4) Indice: ogni documento è elencato in docs/README.md.
//
// Esclusi dai controlli 2–3: docs/modifiche/ (il registro cita i nomi di allora), docs/reference/
// e files_fullpath.txt (elenco storico dei file).
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, normalize, posix } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const THEMES = ["configurazione", "guide", "roadmap", "progetto", "PR", "step"];
const OWN_RULES = ["modifiche", "reference"];
const EXCLUDED = [/^docs\/modifiche\//, /^docs\/reference\//, /^files_fullpath\.txt$/];
// Modelli scritti nelle regole (CLAUDE.md, indice), non percorsi veri.
const PLACEHOLDER = /AAAA|PRxx|prNN|STEP_n\//;

const errors = [];
const fail = (file, message) => errors.push(`${file}: ${message}`);

const tracked = execFileSync("git", ["ls-files", "-z"], { cwd: root, encoding: "utf8" })
  .split("\0")
  .filter((path) => path && existsSync(join(root, path)));
const readText = (path) => {
  const buffer = readFileSync(join(root, path));
  return buffer.subarray(0, 8000).includes(0) ? null : buffer.toString("utf8");
};

function validDate(text) {
  const date = new Date(`${text}T00:00:00Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== text) return false;
  return date.getTime() <= Date.now() + 36 * 3600 * 1000; // niente date nel futuro (fusi orari a parte)
}

// 1) Nomi e cartelle.
const DOC_NAME = /^(\d{4}-\d{2}-\d{2})_([A-Za-z0-9][A-Za-z0-9_]*)\.md$/;
const LOG_NAME = /^(\d{4}-\d{2}-\d{2})_pr\d+-[a-z0-9]+(-[a-z0-9]+)*\.md$/;
const docs = []; // { path, rel, stem }
for (const path of tracked.filter((p) => p.startsWith("docs/") && p.endsWith(".md"))) {
  const parts = path.split("/");
  const name = parts.at(-1);
  if (path === "docs/README.md") continue;
  if (parts.length === 2) {
    fail(path, `documento fuori dalle cartelle a tema (${THEMES.join(", ")})`);
    continue;
  }
  const theme = parts[1];
  if (theme === "reference") continue;
  if (theme === "modifiche") {
    const match = LOG_NAME.exec(name);
    if (parts.length !== 3 || !match || !validDate(match[1])) {
      fail(path, "il registro si chiama docs/modifiche/AAAA-MM-GG_prNN-titolo-breve.md");
    }
    continue;
  }
  if (!THEMES.includes(theme)) {
    fail(path, `cartella sconosciuta: usare ${[...THEMES, ...OWN_RULES].join(", ")}`);
    continue;
  }
  if (theme === "PR" && (parts.length !== 4 || !/^PR\d+(-\d+)?_[a-z0-9]+(-[a-z0-9]+)*$/.test(parts[2]))) {
    fail(path, "i documenti delle PR stanno in docs/PR/PRxx-yy_tema/");
  }
  if (theme === "step" && (parts.length !== 4 || !/^STEP_\d+(_\d+)?$/.test(parts[2]))) {
    fail(path, "i documenti degli step stanno in docs/step/STEP_n/");
  }
  const match = DOC_NAME.exec(name);
  if (!match || !validDate(match[1])) {
    fail(path, "il nome deve essere AAAA-MM-GG_NOME.md, con la data dell'ultimo aggiornamento");
    continue;
  }
  docs.push({ path, rel: parts.slice(1).join("/"), name, stem: match[2] });
}

const byStem = new Map();
for (const doc of docs) {
  const same = byStem.get(doc.stem);
  if (same) fail(doc.path, `stesso documento di ${same.path}: tenere solo la versione aggiornata`);
  else byStem.set(doc.stem, doc);
}

// 2) Riferimenti in tutti i file di testo del repository.
const DOCS_PATH = /(?<![A-Za-z0-9_.\/-])docs\/[A-Za-z0-9_.\/-]*/g;
const BARE_NAME = /(?<![A-Za-z0-9_.\/-])(?:(\d{4}-\d{2}-\d{2})_)?([A-Z0-9][A-Za-z0-9_]*)\.md\b/g;
const markdownFiles = [];
for (const path of tracked) {
  if (EXCLUDED.some((rule) => rule.test(path))) continue;
  const text = readText(path);
  if (text === null) continue;
  if (path.endsWith(".md")) markdownFiles.push([path, text]);
  text.split("\n").forEach((line, index) => {
    const where = `${path}:${index + 1}`;
    for (const [token] of line.matchAll(DOCS_PATH)) {
      const target = token.replace(/[.,;:]+$/, "");
      if (PLACEHOLDER.test(target)) continue;
      if (!existsSync(join(root, target))) fail(where, `${target} non esiste`);
    }
    for (const [token, date, stem] of line.matchAll(BARE_NAME)) {
      const doc = byStem.get(stem);
      if (!doc) continue;
      if (!date) fail(where, `${token} citato senza data: il documento è ${doc.path}`);
      else if (`${date}_${stem}.md` !== doc.name) fail(where, `${token} è un nome superato: ora è ${doc.path}`);
    }
  });
}

// 3) Link relativi dei file Markdown.
const LINK = /\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g;
for (const [path, text] of markdownFiles) {
  const withoutCode = text.replace(/^[ \t]*(```|~~~)[^\n]*\n[\s\S]*?^[ \t]*\1[^\n]*$/gm, (block) => "\n".repeat(block.split("\n").length - 1));
  withoutCode.split("\n").forEach((line, index) => {
    for (const [, raw] of line.matchAll(LINK)) {
      if (/^([a-z][a-z0-9+.-]*:|#)/i.test(raw)) continue;
      let target = raw.replace(/[#?].*$/, "");
      try {
        target = decodeURIComponent(target);
      } catch {
        // lascia il link com'è: lo segnala il controllo qui sotto
      }
      const resolved = target.startsWith("/") ? normalize(join(root, target)) : normalize(join(root, dirname(path), target));
      if (!existsSync(resolved)) fail(`${path}:${index + 1}`, `link rotto: ${raw}`);
    }
  });
}

// 4) Indice.
const index = existsSync(join(root, "docs/README.md")) ? readFileSync(join(root, "docs/README.md"), "utf8") : "";
if (!index) fail("docs/README.md", "manca l'indice dei documenti");
for (const doc of docs) {
  if (!index.includes(`](${posix.normalize(doc.rel)})`)) fail(doc.path, "non è elencato in docs/README.md");
}

if (errors.length) {
  console.error(`Documenti: ${errors.length} problemi.\n${errors.map((e) => `  - ${e}`).join("\n")}`);
  console.error("Regole in CLAUDE.md (sezione «Documenti in docs/») e indice in docs/README.md.");
  process.exit(1);
}
console.log(`Documenti: ${docs.length} documenti a tema, nomi, riferimenti, link e indice a posto.`);
