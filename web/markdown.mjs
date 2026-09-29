// Markdown essenziale per le pagine legali (stessi file mostrati nell'app).
// Titoli, paragrafi, elenchi, tabelle, citazioni, grassetto, corsivo, link http/https/mailto/relativi.
// ---------------------------------------------------------------------------
export function escapeHtml(text) {
  return text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

function inline(text) {
  return escapeHtml(text)
    .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
    .replace(/(^|[\s(])\*(?!\s)(.+?)\*(?=[\s).,;:!?]|$)/g, "$1<em>$2</em>")
    .replace(/(^|[\s(])_(?!\s)(.+?)_(?=[\s).,;:!?]|$)/g, "$1<em>$2</em>")
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+|\/[^)\s]*|mailto:[^)\s]+)\)/g, '<a href="$2">$1</a>');
}

export function markdownToHtml(markdown) {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  const out = [];
  let paragraph = [];
  let list = null; // "ul" | "ol"
  let table = [];

  const flushParagraph = () => {
    if (paragraph.length) out.push(`<p>${paragraph.map(inline).join(" ")}</p>`);
    paragraph = [];
  };
  const flushList = () => {
    if (list) out.push(`</${list}>`);
    list = null;
  };
  const flushTable = () => {
    if (!table.length) return;
    const rows = table
      .filter((row) => !/^\|?\s*:?-{3,}/.test(row))
      .map((row) => row.replace(/^\|/, "").replace(/\|$/, "").split("|").map((cell) => inline(cell.trim())));
    const [head, ...body] = rows;
    out.push(
      "<div class=\"table\"><table><thead><tr>" + head.map((c) => `<th>${c}</th>`).join("") + "</tr></thead><tbody>" +
        body.map((r) => "<tr>" + r.map((c) => `<td>${c}</td>`).join("") + "</tr>").join("") +
        "</tbody></table></div>",
    );
    table = [];
  };
  const flushAll = () => {
    flushParagraph();
    flushList();
    flushTable();
  };

  for (const raw of lines) {
    const line = raw.trimEnd();
    if (!line.trim()) {
      flushAll();
      continue;
    }
    if (line.trim().startsWith("|")) {
      flushParagraph();
      flushList();
      table.push(line.trim());
      continue;
    }
    flushTable();
    const heading = line.match(/^(#{1,4})\s+(.*)$/);
    if (heading) {
      flushAll();
      const level = heading[1].length;
      out.push(`<h${level}>${inline(heading[2])}</h${level}>`);
      continue;
    }
    if (/^-{3,}$/.test(line.trim())) {
      flushAll();
      out.push("<hr>");
      continue;
    }
    const quote = line.match(/^>\s?(.*)$/);
    if (quote) {
      flushAll();
      out.push(`<blockquote>${inline(quote[1])}</blockquote>`);
      continue;
    }
    const bullet = line.match(/^\s*[-*]\s+(.*)$/);
    const numbered = line.match(/^\s*\d+[.)]\s+(.*)$/);
    if (bullet || numbered) {
      flushParagraph();
      const kind = bullet ? "ul" : "ol";
      if (list !== kind) {
        flushList();
        out.push(`<${kind}>`);
        list = kind;
      }
      out.push(`<li>${inline((bullet ?? numbered)[1])}</li>`);
      continue;
    }
    if (list && /^\s{2,}\S/.test(raw)) {
      // Continuazione di una voce d'elenco.
      out[out.length - 1] = out[out.length - 1].replace(/<\/li>$/, ` ${inline(line.trim())}</li>`);
      continue;
    }
    flushList();
    // Le clausole numerate (es. "2.1 ...") iniziano un nuovo paragrafo.
    if (/^\d+\.\d+\s/.test(line)) flushParagraph();
    paragraph.push(line.trim());
  }
  flushAll();
  return out.join("\n");
}
