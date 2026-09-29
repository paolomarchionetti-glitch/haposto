// node --test "web/tests/*.test.mjs"
import { test } from "node:test";
import assert from "node:assert/strict";

import { markdownToHtml } from "../markdown.mjs";

test("titoli, grassetto e link", () => {
  const html = markdownToHtml("# Titolo\n\nTesto **forte** e [link](https://haposto.app).");
  assert.match(html, /<h1>Titolo<\/h1>/);
  assert.match(html, /<strong>forte<\/strong>/);
  assert.match(html, /<a href="https:\/\/haposto.app">link<\/a>/);
});

test("le clausole numerate restano paragrafi separati", () => {
  const html = markdownToHtml("2.1 Prima clausola\n2.2 Seconda clausola");
  assert.equal((html.match(/<p>/g) ?? []).length, 2);
});

test("tabelle ed elenchi", () => {
  const html = markdownToHtml("| A | B |\n|---|---|\n| 1 | 2 |\n\n- uno\n- due");
  assert.match(html, /<th>A<\/th><th>B<\/th>/);
  assert.match(html, /<td>1<\/td><td>2<\/td>/);
  assert.match(html, /<ul>\n<li>uno<\/li>\n<li>due<\/li>\n<\/ul>/);
});

test("l'HTML nel testo viene neutralizzato", () => {
  const html = markdownToHtml("<script>alert(1)</script> e [x](javascript:alert(1))");
  assert.ok(!html.includes("<script>"));
  assert.ok(!html.includes('href="javascript'));
});
