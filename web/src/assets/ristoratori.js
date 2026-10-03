// Area ristoratori del sito: accesso Google + verifica in due passaggi, dati di fatturazione,
// attivazione e gestione dell'abbonamento Pro (Stripe). Tutte le regole sono sul server:
// questa pagina mostra solo ciò che il database e le Edge Function permettono.
(function () {
  const { config, el } = window.HAPOSTO;
  const app = document.getElementById("app");
  const messages = document.getElementById("messages");

  const ERRORS = {
    AUTH_REQUIRED: "Accedi di nuovo con Google.",
    MFA_REQUIRED: "Serve la verifica in due passaggi.",
    OWNER_REQUIRED: "Solo il titolare del locale può gestire l'abbonamento.",
    NOT_AUTHORIZED: "Non gestisci questo locale.",
    ACCOUNT_BLOCKED: "Account sospeso: scrivi all'assistenza.",
    RESTAURANT_NOT_ACTIVE: "Il locale non è ancora attivo su HAPOSTO.",
    RESTAURANT_SUSPENDED: "Il locale è sospeso: contatta HAPOSTO.",
    BILLING_PROFILE_REQUIRED: "Prima salva i dati di fatturazione.",
    ALREADY_SUBSCRIBED: "Il locale ha già Pro: usa \"Gestisci abbonamento\".",
    NO_STRIPE_CUSTOMER: "Non ci sono ancora abbonamenti pagati per questo locale.",
    NOT_CONFIGURED: "Pagamenti non ancora attivi. Riprova più avanti.",
    STRIPE_ERROR: "Stripe non ha risposto: riprova tra qualche minuto.",
    SPECIFIC_CLAUSES_REQUIRED: "Serve l'approvazione specifica delle clausole indicate.",
  };

  function show(text, kind = "") {
    messages.replaceChildren(el("div", { class: `banner ${kind}` }, text));
    messages.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }

  async function errorMessage(error) {
    let code = "";
    try {
      const body = await error.context?.json?.();
      code = body?.error ?? "";
    } catch (_) {
      code = "";
    }
    if (!code) code = Object.keys(ERRORS).find((key) => String(error?.message ?? "").includes(key)) ?? "";
    return ERRORS[code] ?? "Operazione non riuscita. Riprova.";
  }

  if (!config.supabaseUrl || !config.supabaseKey || !window.supabase) {
    app.replaceChildren(el("p", {}, "L'area ristoratori non è ancora attiva. Scrivici a ",
      el("a", { href: `mailto:${config.contactEmail}` }, config.contactEmail), "."));
    return;
  }

  const client = window.supabase.createClient(config.supabaseUrl, config.supabaseKey, {
    auth: { flowType: "pkce", detectSessionInUrl: true, persistSession: true },
  });

  const outcome = new URLSearchParams(location.search).get("esito");
  if (outcome === "ok") show("✓ Pagamento ricevuto: Pro si attiva nell'app entro un minuto. Riceverai la fattura via email.");
  if (outcome === "annullato") show("Pagamento annullato: nessun addebito.", "warn");

  loadPrice();
  client.auth.onAuthStateChange((event) => {
    if (event === "SIGNED_OUT") render();
  });
  document.getElementById("signout").addEventListener("click", async (event) => {
    event.preventDefault();
    await client.auth.signOut();
    render();
  });
  render();

  async function loadPrice() {
    const { data } = await client.from("plans")
      .select("price_month_cents, price_semester_cents, price_year_cents, prices_include_vat")
      .eq("code", "RESTAURANT_PRO")
      .maybeSingle();
    if (!data?.price_month_cents) return;
    const semester = data.price_semester_cents != null ? `, ${euro(data.price_semester_cents)} per 6 mesi` : "";
    document.getElementById("price").textContent =
      `${euro(data.price_month_cents)} al mese${semester} o ${euro(data.price_year_cents)} l'anno` +
      (data.prices_include_vat ? ", IVA inclusa" : " + IVA");
  }

  async function render() {
    const { data: { session } } = await client.auth.getSession();
    document.getElementById("signout").classList.toggle("hidden", !session);
    if (!session) return renderSignIn();

    const { data: aal } = await client.auth.mfa.getAuthenticatorAssuranceLevel();
    if (aal?.currentLevel !== "aal2") return renderMfa(aal?.nextLevel === "aal2", session.user.email);
    return renderRestaurants(session.user);
  }

  function renderSignIn() {
    app.replaceChildren(
      el("h2", {}, "Accedi"),
      el("p", {}, "Usa lo stesso account Google con cui gestisci il locale nell'app."),
      el("button", {
        class: "button",
        onclick: () => client.auth.signInWithOAuth({
          provider: "google",
          // Chi ha più account Google nel browser sceglie sempre quale usare.
          options: { redirectTo: `${location.origin}/ristoratori/`, queryParams: { prompt: "select_account" } },
        }),
      }, "Accedi con Google"),
    );
  }

  function renderMfa(hasFactor, email) {
    // Con più account Google è facile entrare con quello sbagliato: lo si mostra sempre.
    const account = el("p", { class: "muted" }, "Account: ", el("strong", {}, email ?? ""),
      " · non è quello giusto? Premi «Esci» in alto e accedi con l'altro.");
    if (!hasFactor) {
      app.replaceChildren(
        el("h2", {}, "Serve la verifica in due passaggi"),
        account,
        el("p", {}, "Per proteggere il tuo locale, attivala prima nell'app HAPOSTO: Account → ",
          el("strong", {}, "Verifica in due passaggi"), ". Poi torna qui e ricarica la pagina."),
      );
      return;
    }
    const input = el("input", {
      type: "text", inputmode: "numeric", autocomplete: "one-time-code", maxlength: "6",
      class: "code-input", "aria-label": "Codice a 6 cifre",
    });
    const button = el("button", { class: "button" }, "Verifica");
    button.addEventListener("click", async () => {
      const code = input.value.replace(/\D/g, "");
      if (code.length !== 6) return show("Scrivi le 6 cifre dell'app di autenticazione.", "error");
      button.disabled = true;
      const { data: factors } = await client.auth.mfa.listFactors();
      const factor = factors?.totp?.find((f) => f.status === "verified");
      if (!factor) {
        button.disabled = false;
        return renderMfa(false, email);
      }
      const { error } = await client.auth.mfa.challengeAndVerify({ factorId: factor.id, code });
      button.disabled = false;
      if (error?.status === 429) return show("Troppi tentativi: aspetta qualche minuto e riprova.", "error");
      if (error) return show("Codice sbagliato o scaduto: riprova con quello nuovo.", "error");
      messages.replaceChildren();
      render();
    });
    app.replaceChildren(
      el("h2", {}, "Verifica in due passaggi"),
      account,
      el("p", {}, "Apri l'app di autenticazione (Google Authenticator, Microsoft Authenticator…) e scrivi il codice di HAPOSTO con questa email."),
      input, el("p", {}, button),
    );
    input.focus();
  }

  async function renderRestaurants(user) {
    const { data, error } = await client.rpc("my_restaurants");
    if (error) return show(await errorMessage(error), "error");
    const owned = (data ?? []).filter((r) => r.role === "OWNER");
    if (owned.length === 0) {
      app.replaceChildren(
        el("h2", {}, "Nessun locale di cui sei titolare"),
        el("p", {}, `Account: ${user.email}. Rivendica o registra il tuo locale dall'app (tab Ristoratore): dopo la verifica comparirà qui.`),
      );
      return;
    }
    const list = el("div", {});
    for (const restaurant of owned) {
      list.append(el("p", {},
        el("button", { class: "button secondary", onclick: () => renderRestaurant(restaurant.restaurant_id) },
          `${restaurant.name}${restaurant.city ? " · " + restaurant.city : ""}`)));
    }
    app.replaceChildren(el("h2", {}, "I tuoi locali"), el("p", { class: "muted" }, user.email), list);
    if (owned.length === 1) renderRestaurant(owned[0].restaurant_id);
  }

  async function renderRestaurant(restaurantId) {
    const { data: infoRows, error } = await client.rpc("restaurant_manager_info", { p_restaurant_id: restaurantId });
    if (error) return show(await errorMessage(error), "error");
    const info = infoRows?.[0];
    if (!info) return show("Locale non trovato.", "error");

    const [{ data: billing }, { data: profileRows }, { data: proPlan }] = await Promise.all([
      client.from("restaurant_billing_profiles").select("*").eq("restaurant_id", restaurantId).maybeSingle(),
      client.rpc("my_profile"),
      client.from("plans").select("price_month_cents, price_semester_cents, price_year_cents")
        .eq("code", "RESTAURANT_PRO").maybeSingle(),
    ]);
    const profile = profileRows?.[0] ?? {};
    const termsOk = profile.accepted_restaurant_terms_version &&
      profile.accepted_restaurant_terms_version === profile.current_restaurant_terms_version;

    const isStripe = info.plan_source === "STRIPE";
    const validUntil = info.plan_valid_until ? new Date(info.plan_valid_until).toLocaleDateString("it-IT") : null;
    const warning = planWarning(info);
    const canPay = billing && termsOk;
    // Prezzi dal database (IVA inclusa); il semestrale c'è dalla migration 0016.
    const periods = [
      ["MONTH", "mensile", proPlan?.price_month_cents, "al mese"],
      ["SEMESTER", "semestrale", proPlan?.price_semester_cents, "ogni 6 mesi"],
      ["YEAR", "annuale", proPlan?.price_year_cents, "all'anno"],
    ].filter(([interval, , cents]) => interval !== "SEMESTER" || cents != null);

    // replaceChildren scriverebbe "null" al posto delle parti assenti: si tolgono prima.
    app.replaceChildren(...[
      el("h2", {}, info.name),
      el("p", {}, "Piano attuale: ", el("strong", {}, info.plan_name || info.plan_code),
        validUntil ? ` · fino al ${validUntil}` : "",
        info.plan_source && info.plan_source !== "STRIPE" ? ` (${sourceLabel(info.plan_source)})` : ""),
      warning ? el("div", { class: "banner warn" }, warning) : null,
      termsOk ? null : termsCard(profile.current_restaurant_terms_version, () => renderRestaurant(restaurantId)),
      billingForm(restaurantId, billing, () => renderRestaurant(restaurantId)),
      el("div", { class: "card" },
        el("h3", {}, "Abbonamento Pro"),
        isStripe
          ? el("p", {}, "Cambia carta, scarica le fatture o disdici (vale fino alla fine del periodo pagato).")
          : el("p", {}, "Rinnovo automatico, disdici quando vuoi. Il pagamento avviene sulla pagina sicura di Stripe."),
        isStripe
          ? el("button", { class: "button", onclick: () => openPortal(restaurantId) }, "Gestisci abbonamento")
          : el("p", {}, periods.flatMap(([interval, label, cents, per], index) => [
              el("button", {
                class: index === 0 ? "button" : "button secondary",
                disabled: !canPay,
                onclick: () => checkout(restaurantId, interval),
              }, `Attiva Pro ${label}${cents != null ? ` · ${euro(cents)} ${per}` : ""}`),
              " ",
            ])),
        isStripe ? null : el("p", { class: "muted small" }, "Prezzi IVA inclusa. Senza piano, finita la prova, il locale resta nella lista come «Non collegato»."),
        !isStripe && (!billing || !termsOk)
          ? el("p", { class: "muted small" }, "Prima accetta le condizioni e salva i dati di fatturazione.")
          : null,
      ),
    ].filter(Boolean));
  }

  function sourceLabel(source) {
    return {
      BETA: "beta gratuita",
      TRIAL: "prova gratuita",
      MANUAL: "attivato da HAPOSTO",
      NONE: "nessun piano: il locale appare «Non collegato»",
      FREE: "gratuito",
    }[source] ?? source.toLowerCase();
  }

  function euro(cents) {
    return (cents / 100).toLocaleString("it-IT", { style: "currency", currency: "EUR" });
  }

  // Come l'app: piano finito, oppure periodo gratuito o dato da HAPOSTO che finisce entro 7 giorni.
  function planWarning(info) {
    if (info.plan_source === "NONE") {
      return "Il periodo gratuito è finito: il locale appare «Non collegato» e lo stato non si pubblica. Attiva Pro qui sotto.";
    }
    if (!info.plan_valid_until || info.plan_source === "STRIPE") return null;
    const end = new Date(info.plan_valid_until);
    const days = (end.getTime() - Date.now()) / 86400000;
    if (days < 0 || days > 7) return null;
    const what = info.plan_source === "MANUAL" ? "Il piano" : "Il periodo gratuito";
    return `${what} finisce il ${end.toLocaleDateString("it-IT")}: poi il locale appare «Non collegato». Per restare collegato attiva Pro qui sotto.`;
  }

  function termsCard(version, onDone) {
    const general = el("input", { type: "checkbox" });
    const specific = el("input", { type: "checkbox" });
    const button = el("button", { class: "button" }, "Accetto");
    button.addEventListener("click", async () => {
      if (!general.checked || !specific.checked) return show("Per continuare servono entrambe le spunte.", "error");
      button.disabled = true;
      const { error } = await client.rpc("accept_restaurant_terms", {
        p_version: version,
        p_specific_clauses_accepted: true,
      });
      button.disabled = false;
      if (error) return show(await errorMessage(error), "error");
      show("✓ Condizioni accettate.");
      onDone();
    });
    return el("div", { class: "card" },
      el("h3", {}, "Condizioni per i ristoranti"),
      el("label", { class: "check" }, general, el("span", {}, "Ho letto e accetto le ",
        el("a", { href: "/termini-ristoranti/", target: "_blank" }, "Condizioni di servizio per i ristoranti"),
        ` (versione ${version}).`)),
      el("label", { class: "check" }, specific, el("span", {},
        "Ai sensi degli artt. 1341 e 1342 c.c. approvo specificamente le clausole 2.3, 4.4, 5.1, 6.2, 8 e 9.")),
      button,
    );
  }

  function billingForm(restaurantId, billing, onSaved) {
    const b = billing ?? {};
    const fields = {
      legal_name: ["Ragione sociale o nome e cognome", b.legal_name, "text"],
      vat_number: ["Partita IVA (11 cifre)", b.vat_number, "text"],
      tax_code: ["Codice fiscale (se diverso o senza P.IVA)", b.tax_code, "text"],
      sdi_code: ["Codice destinatario SDI (7 caratteri)", b.sdi_code, "text"],
      pec_email: ["PEC (se non hai il codice SDI)", b.pec_email, "email"],
      invoice_email: ["Email per ricevere le fatture", b.invoice_email, "email"],
      billing_address: ["Indirizzo di fatturazione", b.billing_address, "text"],
      billing_city: ["Città", b.billing_city, "text"],
      billing_postal_code: ["CAP", b.billing_postal_code, "text"],
      billing_province: ["Provincia (sigla, es. PU)", b.billing_province, "text"],
    };
    const inputs = {};
    const form = el("div", { class: "card" }, el("h3", {}, "Dati di fatturazione"));
    for (const [key, [label, value, type]] of Object.entries(fields)) {
      inputs[key] = el("input", { type, value: value ?? "", id: `f-${key}` });
      form.append(el("label", { for: `f-${key}` }, label), inputs[key]);
    }
    const save = el("button", { class: "button" }, billing ? "Aggiorna dati" : "Salva dati");
    save.addEventListener("click", async () => {
      const value = (key) => inputs[key].value.trim();
      const row = {
        restaurant_id: restaurantId,
        legal_name: value("legal_name"),
        vat_number: value("vat_number").replace(/\s|^IT/gi, "") || null,
        tax_code: value("tax_code").toUpperCase() || null,
        sdi_code: value("sdi_code").toUpperCase() || null,
        pec_email: value("pec_email") || null,
        invoice_email: value("invoice_email") || null,
        billing_address: value("billing_address"),
        billing_city: value("billing_city"),
        billing_postal_code: value("billing_postal_code"),
        billing_province: value("billing_province").toUpperCase(),
      };
      const problem = validateBilling(row);
      if (problem) return show(problem, "error");
      save.disabled = true;
      const { error } = await client.from("restaurant_billing_profiles").upsert(row, { onConflict: "restaurant_id" });
      save.disabled = false;
      if (error) return show("Dati non salvati: controlla i campi (e la verifica in due passaggi).", "error");
      show("✓ Dati di fatturazione salvati.");
      onSaved();
    });
    form.append(el("p", {}, save));
    return form;
  }

  function validateBilling(row) {
    if (row.legal_name.length < 2) return "Scrivi la ragione sociale.";
    if (row.vat_number && !/^[0-9]{11}$/.test(row.vat_number)) return "La partita IVA ha 11 cifre.";
    if (row.tax_code && !/^([A-Z0-9]{16}|[0-9]{11})$/.test(row.tax_code)) return "Codice fiscale non valido.";
    if (!row.vat_number && !row.tax_code) return "Serve la partita IVA o il codice fiscale.";
    if (row.sdi_code && !/^[A-Z0-9]{7}$/.test(row.sdi_code)) return "Il codice SDI ha 7 caratteri.";
    if (!row.sdi_code && !row.pec_email) return "Serve il codice SDI o la PEC.";
    if (row.billing_address.length < 3) return "Scrivi l'indirizzo di fatturazione.";
    if (row.billing_city.length < 2) return "Scrivi la città.";
    if (!/^[0-9]{5}$/.test(row.billing_postal_code)) return "Il CAP ha 5 cifre.";
    if (!/^[A-Z]{2}$/.test(row.billing_province)) return "La provincia è la sigla di 2 lettere.";
    return null;
  }

  async function checkout(restaurantId, interval) {
    show("Apro la pagina di pagamento…", "warn");
    const { data, error } = await client.functions.invoke("stripe-checkout", { body: { restaurantId, interval } });
    if (error || !data?.url) return show(error ? await errorMessage(error) : "Pagamento non disponibile.", "error");
    location.href = data.url;
  }

  async function openPortal(restaurantId) {
    const { data, error } = await client.functions.invoke("billing-portal", { body: { restaurantId } });
    if (error || !data?.url) return show(error ? await errorMessage(error) : "Portale non disponibile.", "error");
    location.href = data.url;
  }
})();
