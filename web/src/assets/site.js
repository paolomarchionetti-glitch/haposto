// Funzioni comuni alle pagine del sito (nessuna libreria).
(function () {
  const config = window.HAPOSTO_CONFIG || {};

  const STATUS = {
    AVAILABLE: { label: "C'è posto", css: "AVAILABLE" },
    LIMITED: { label: "Pochi posti", css: "LIMITED" },
    FULL: { label: "Completo", css: "FULL" },
  };

  /** Chiamata a una funzione SQL pubblica (solo quelle concesse al ruolo anon). */
  async function publicRpc(name, args) {
    if (!config.supabaseUrl || !config.supabaseKey) throw new Error("NOT_CONFIGURED");
    const response = await fetch(`${config.supabaseUrl}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: {
        apikey: config.supabaseKey,
        Authorization: `Bearer ${config.supabaseKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(args || {}),
    });
    if (!response.ok) throw new Error(`HTTP_${response.status}`);
    const text = await response.text();
    return text ? JSON.parse(text) : null;
  }

  /** Stato valido solo se non scaduto (30 minuti), come nell'app. */
  function liveStatus(row, now = new Date()) {
    if (!row || !row.live_status || !row.live_valid_until) return null;
    if (new Date(row.live_valid_until) <= now) return null;
    return STATUS[row.live_status] || null;
  }

  function minutesAgo(iso, now = new Date()) {
    const minutes = Math.max(0, Math.round((now - new Date(iso)) / 60000));
    return minutes <= 1 ? "adesso" : `${minutes} minuti fa`;
  }

  function el(tag, attrs, ...children) {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs || {})) {
      if (value === null || value === undefined || value === false) continue;
      if (key === "class") node.className = value;
      else if (key.startsWith("on")) node.addEventListener(key.slice(2), value);
      else node.setAttribute(key, value === true ? "" : String(value));
    }
    for (const child of children.flat()) {
      if (child === null || child === undefined || child === false) continue;
      node.append(child instanceof Node ? child : document.createTextNode(String(child)));
    }
    return node;
  }

  window.HAPOSTO = { config, publicRpc, liveStatus, minutesAgo, el, STATUS };
})();
