// MDM Smart – pagina "Casa"
// Si costruisce da sola con i dispositivi della casa:
//   intestazione "Ciao, <nome>", Monitoraggio Energia, Comandi Rapidi, Le tue stanze
//   sfondo animato (meteo, notte, Natale, compleanni)
// Personalizzabile per ogni casa nella configurazione della dashboard:
//   strategy:
//     type: custom:mdm-casa
//     sottotitolo: Benvenuto nel tuo MDM Impianti smart
//     comandi: [climate.sala, alarm_control_panel.casa]   (facoltativo)
//     consumo: sensor.potenza_casa                         (facoltativo)
//     compleanni: [{nome: Marco, data: "11-27"}]           (facoltativo)
//     sfondo: auto | sole | nuvole | pioggia | neve | notte | natale | compleanno | nessuno
(() => {
  const SFONDI = "/local/mdm/sfondi/";
  const LOGO = "/static/icons/favicon-512x512.png";
  const COLORI = ["#22c55e", "#8b5cf6", "#f59e0b", "#3b82f6", "#ef4444", "#14b8a6", "#ec4899", "#a3a3a3"];
  const DOMINI_COMANDI = ["climate", "alarm_control_panel", "humidifier", "water_heater", "lock", "cover", "fan"];
  const NASCOSTI = new Set(["sensor.mdm_preparazione"]);

  const sx = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  // ---------- dati della casa ----------
  function entitaVisibili(hass) {
    const reg = hass.entities || {};
    return Object.keys(hass.states).filter((id) => {
      if (NASCOSTI.has(id)) return false;
      const e = reg[id];
      if (!e) return true;
      return !e.hidden && !e.entity_category;
    });
  }

  function areaDi(hass, id) {
    const e = hass.entities?.[id];
    if (!e) return undefined;
    if (e.area_id) return e.area_id;
    return e.device_id ? hass.devices?.[e.device_id]?.area_id : undefined;
  }

  function trovaConsumo(hass, ids) {
    const candidati = ids.filter((id) => {
      const a = hass.states[id].attributes;
      return id.startsWith("sensor.") && a.device_class === "power" && !isNaN(parseFloat(hass.states[id].state));
    });
    const pref = candidati.find((id) => /casa|total|consum|rete|grid|house|home/i.test(id + " " + (hass.states[id].attributes.friendly_name || "")));
    return pref || candidati[0];
  }

  function compleannoOggi(config) {
    const oggi = new Date();
    const mmgg = `${String(oggi.getMonth() + 1).padStart(2, "0")}-${String(oggi.getDate()).padStart(2, "0")}`;
    return (config.compleanni || []).find((c) => String(c.data || "").slice(-5) === mmgg);
  }

  function sceltaSfondo(hass, config) {
    if (config.sfondo && config.sfondo !== "auto") return config.sfondo;
    if (compleannoOggi(config)) return "compleanno";
    const d = new Date();
    if ((d.getMonth() === 11 && d.getDate() >= 1) || (d.getMonth() === 0 && d.getDate() <= 6)) return "natale";
    const meteo = Object.keys(hass.states).find((id) => id.startsWith("weather."));
    const s = meteo ? hass.states[meteo].state : "";
    if (/snow/.test(s)) return "neve";
    if (/rain|pouring|lightning|hail/.test(s)) return "pioggia";
    const notte = hass.states["sun.sun"]?.state === "below_horizon" || s === "clear-night";
    if (notte) return "notte";
    if (/cloud|fog|partly/.test(s)) return "nuvole";
    return "sole";
  }

  function sfondo(nome) {
    if (!nome || nome === "nessuno") return undefined;
    return `url("${SFONDI}${nome}.svg") right top / cover no-repeat fixed, var(--primary-background-color)`;
  }

  const indietro = (dove = "casa") => ({ type: "custom:mdm-indietro", naviga: `/lovelace/${dove}` });

  // ---------- strategia della dashboard ----------
  class MdmCasaStrategy extends HTMLElement {
    static async generate(config, hass) {
      config = config || {};
      const ids = entitaVisibili(hass);
      const nomeSfondo = sceltaSfondo(hass, config);
      const bg = sfondo(nomeSfondo);
      const festeggiato = compleannoOggi(config);

      // Energia
      const consumo = config.consumo || trovaConsumo(hass, ids);
      const sezioni = [
        {
          type: "grid",
          column_span: 3,
          cards: [{
            type: "custom:mdm-benvenuto",
            sottotitolo: config.sottotitolo || "Benvenuto nel tuo MDM Impianti smart",
            compleanno: festeggiato ? festeggiato.nome : undefined,
          }],
        },
      ];

      if (consumo) {
        sezioni.push({
          type: "grid",
          cards: [
            { type: "custom:mdm-titolo", titolo: "Monitoraggio Energia", sottotitolo: "Gestione consumi e statistiche" },
            { type: "custom:mdm-pulsante", icona: "mdi:flash", titolo: "Istantaneo", entita: consumo, colore: "#ef4444" },
            { type: "custom:mdm-pulsante", icona: "mdi:chart-box-outline", titolo: "Analisi Energia", sottotitolo: "Grafici e Storico", naviga: "/lovelace/energia", colore: "#22c55e" },
          ],
        });
      }

      // Comandi rapidi
      let comandi = config.comandi;
      if (!comandi) {
        comandi = ids
          .filter((id) => DOMINI_COMANDI.includes(id.split(".")[0]))
          .sort((a, b) => DOMINI_COMANDI.indexOf(a.split(".")[0]) - DOMINI_COMANDI.indexOf(b.split(".")[0]))
          .slice(0, 8);
        if (comandi.length < 4) {
          comandi = comandi.concat(ids.filter((id) => /^(light|switch)\./.test(id)).slice(0, 8 - comandi.length));
        }
      }
      if (comandi.length) {
        sezioni.push({
          type: "grid",
          cards: [
            { type: "custom:mdm-titolo", titolo: "Comandi Rapidi" },
            ...comandi.map((id) => ({ type: "tile", entity: id, vertical: true, grid_options: { columns: 3, rows: 2 }, features_position: "bottom" })),
          ],
        });
      }

      // Stanze
      const aree = Object.values(hass.areas || {}).filter((a) => ids.some((id) => areaDi(hass, id) === a.area_id));
      aree.sort((a, b) => a.name.localeCompare(b.name, "it"));
      if (aree.length) {
        sezioni.push({
          type: "grid",
          cards: [
            { type: "custom:mdm-titolo", titolo: "Le tue stanze", sottotitolo: "Tocca per gestire gli ambienti" },
            ...aree.map((a, i) => ({
              type: "custom:mdm-pulsante",
              icona: a.icon || "mdi:home-outline",
              titolo: a.name,
              colore: COLORI[i % COLORI.length],
              naviga: `/lovelace/stanza-${a.area_id}`,
              piatto: true,
            })),
          ],
        });
      }

      sezioni.push({
        type: "grid",
        cards: [
          { type: "custom:mdm-titolo", titolo: "Le mie automazioni" },
          { type: "custom:mdm-pulsante", icona: "mdi:clock-outline", titolo: "Programmi e orari", sottotitolo: "Crea le tue automazioni", naviga: "/lovelace/automazioni", colore: "#8b5cf6", grid_options: { columns: 12 } },
        ],
      });

      const viste = [
        { title: "Casa", path: "casa", icon: "mdi:home", type: "sections", max_columns: 3, background: bg, sections: sezioni },
        {
          title: "Le mie automazioni", path: "automazioni", subview: true, type: "sections", max_columns: 1, background: bg,
          sections: [{ type: "grid", cards: [indietro(), { type: "custom:mdm-titolo", titolo: "Le mie automazioni", sottotitolo: "Accendi e spegni in automatico, agli orari che vuoi" }, { type: "custom:scheduler-card", grid_options: { columns: 12 } }] }],
        },
      ];

      // Analisi energia
      if (consumo) {
        const energia = ids.filter((id) => id.startsWith("sensor.") && hass.states[id].attributes.device_class === "energy" && hass.states[id].attributes.state_class);
        const carte = [
          indietro(),
          { type: "custom:mdm-titolo", titolo: "Analisi Energia", sottotitolo: "Consumi di oggi e degli ultimi giorni" },
          { type: "history-graph", title: "Potenza (ultime 24 ore)", hours_to_show: 24, entities: [consumo], grid_options: { columns: 12 } },
        ];
        if (energia.length) {
          carte.push({ type: "statistics-graph", title: "Energia al giorno", chart_type: "bar", period: "day", days_to_show: 14, stat_types: ["change"], entities: energia.slice(0, 4), grid_options: { columns: 12 } });
        }
        viste.push({ title: "Analisi Energia", path: "energia", subview: true, type: "sections", max_columns: 1, background: bg, sections: [{ type: "grid", cards: carte }] });
      }

      // Una pagina per ogni stanza
      for (const a of aree) {
        const dentro = ids.filter((id) => areaDi(hass, id) === a.area_id && !/^(sensor|binary_sensor|update|button|event|number|select|text|image|camera|scene|script|automation)\./.test(id));
        const sensori = ids.filter((id) => areaDi(hass, id) === a.area_id && /^(sensor|binary_sensor)\./.test(id));
        const carte = [indietro(), { type: "custom:mdm-titolo", titolo: a.name }];
        for (const id of dentro) carte.push({ type: "tile", entity: id, features_position: "bottom" });
        if (sensori.length) {
          carte.push({ type: "custom:mdm-titolo", titolo: "Sensori" });
          for (const id of sensori) carte.push({ type: "tile", entity: id, grid_options: { columns: 6 } });
        }
        viste.push({ title: a.name, path: `stanza-${a.area_id}`, subview: true, type: "sections", max_columns: 2, background: bg, sections: [{ type: "grid", column_span: 2, cards: carte }] });
      }

      return {
        kiosk_mode: {
          hide_sidebar: true,
          hide_menubutton: true,
          hide_header: true,
          non_admin_settings: {
            hide_sidebar: true,
            hide_menubutton: true,
            hide_header: true,
            hide_search: true,
            hide_assistant: true,
            hide_edit_dashboard: true,
            hide_settings: true,
            hide_add_to_home_assistant: true,
            hide_dialog_header_settings: true,
            hide_dialog_header_add_to: true,
            hide_dialog_update_actions: true,
          },
          ...(config.kiosk_mode || {}),
        },
        views: viste,
      };
    }
  }

  // ---------- carte ----------
  const BASE = `
    :host{display:block}
    *{box-sizing:border-box}
    .t{font-family:var(--ha-font-family-body,Roboto,system-ui,sans-serif)}
  `;

  class Carta extends HTMLElement {
    setConfig(c) { this._c = c || {}; this._disegna(); }
    set hass(h) { this._h = h; this._aggiorna?.(); }
    getCardSize() { return 1; }
    getGridOptions() { return { columns: 12, rows: "auto" }; }
    _vai(url) {
      history.pushState(null, "", url);
      window.dispatchEvent(new CustomEvent("location-changed", { detail: { replace: false } }));
    }
  }

  class MdmBenvenuto extends Carta {
    _disegna() {
      if (!this.shadowRoot) this.attachShadow({ mode: "open" });
      this.shadowRoot.innerHTML = `
        <style>${BASE}
          .box{display:flex;align-items:center;gap:14px;padding:18px 6px 6px}
          img{width:54px;height:54px;flex:none;filter:drop-shadow(0 2px 8px rgba(139,92,246,.35))}
          .testi{flex:1;min-width:0}
          h1{margin:0;font-size:19px;font-weight:700;color:var(--primary-text-color)}
          p{margin:2px 0 0;font-size:14px;color:var(--secondary-text-color)}
          .festa{color:#f59e0b}
          button{border:0;background:var(--card-background-color);color:var(--secondary-text-color);width:42px;height:42px;border-radius:50%;cursor:pointer;display:none;align-items:center;justify-content:center}
          button.si{display:flex}
          ha-icon{--mdc-icon-size:22px}
        </style>
        <div class="box t">
          <img src="${LOGO}" alt="MDM Smart">
          <div class="testi"><h1 class="ciao"></h1><p class="sotto"></p></div>
          <button class="tec" title="Impostazioni (tecnico)"><ha-icon icon="mdi:cog-outline"></ha-icon></button>
        </div>`;
      this.shadowRoot.querySelector(".tec").onclick = () => this._vai("/config/dashboard");
      this._aggiorna();
    }
    _aggiorna() {
      if (!this.shadowRoot || !this._h) return;
      const nome = (this._h.user?.name || "").split(" ")[0];
      const ciao = this.shadowRoot.querySelector(".ciao");
      const sotto = this.shadowRoot.querySelector(".sotto");
      if (this._c.compleanno) {
        ciao.innerHTML = `<span class="festa">Buon compleanno, ${sx(this._c.compleanno)}!</span>`;
      } else {
        ciao.textContent = nome ? `Ciao, ${nome}` : "Ciao";
      }
      sotto.textContent = this._c.sottotitolo || "";
      this.shadowRoot.querySelector(".tec").classList.toggle("si", !!this._h.user?.is_admin);
    }
  }

  class MdmTitolo extends Carta {
    _disegna() {
      if (!this.shadowRoot) this.attachShadow({ mode: "open" });
      this.shadowRoot.innerHTML = `
        <style>${BASE}
          div{padding:22px 6px 4px}
          h2{margin:0;font-size:26px;font-weight:400;color:var(--primary-text-color);letter-spacing:-.2px}
          p{margin:8px 0 0;font-size:16px;color:var(--secondary-text-color)}
        </style>
        <div class="t"><h2>${sx(this._c.titolo)}</h2>${this._c.sottotitolo ? `<p>${sx(this._c.sottotitolo)}</p>` : ""}</div>`;
    }
  }

  class MdmPulsante extends Carta {
    getGridOptions() { return { columns: 6, rows: "auto" }; }
    _disegna() {
      if (!this.shadowRoot) this.attachShadow({ mode: "open" });
      const col = this._c.colore || "var(--primary-color)";
      const piatto = !!this._c.piatto;
      this.shadowRoot.innerHTML = `
        <style>${BASE}
          ha-card{display:flex;align-items:center;gap:14px;padding:${piatto ? "18px 16px" : "14px 14px"};cursor:pointer;
            min-height:68px;transition:transform .12s ease;
            ${piatto ? "" : `background:color-mix(in srgb, ${col} 16%, var(--card-background-color));border-color:color-mix(in srgb, ${col} 35%, transparent);`}}
          ha-card:active{transform:scale(.98)}
          .ic{width:${piatto ? "auto" : "40px"};height:40px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;
            ${piatto ? "" : `background:color-mix(in srgb, ${col} 22%, transparent);`}color:${col}}
          ha-icon{--mdc-icon-size:${piatto ? "28px" : "22px"}}
          .tx{min-width:0}
          b{display:block;font-size:16px;font-weight:600;color:var(--primary-text-color);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
          span{display:block;font-size:13px;color:var(--secondary-text-color);margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
        </style>
        <ha-card class="t">
          <div class="ic"><ha-icon icon="${sx(this._c.icona || "mdi:circle")}"></ha-icon></div>
          <div class="tx"><b>${sx(this._c.titolo)}</b><span class="sotto">${sx(this._c.sottotitolo || "")}</span></div>
        </ha-card>`;
      this.shadowRoot.querySelector("ha-card").onclick = () => {
        if (this._c.naviga) return this._vai(this._c.naviga);
        if (this._c.entita) {
          this.dispatchEvent(new CustomEvent("hass-more-info", { bubbles: true, composed: true, detail: { entityId: this._c.entita } }));
        }
      };
      this._aggiorna();
    }
    _aggiorna() {
      if (!this.shadowRoot || !this._h || !this._c?.entita) return;
      const st = this._h.states[this._c.entita];
      const el = this.shadowRoot.querySelector(".sotto");
      if (!el) return;
      if (!st) { el.textContent = "Non disponibile"; return; }
      const v = parseFloat(st.state);
      const u = st.attributes.unit_of_measurement || "";
      el.textContent = isNaN(v) ? st.state : `${Math.round(v * 10) / 10} ${u}`.trim();
    }
  }

  class MdmIndietro extends Carta {
    _disegna() {
      if (!this.shadowRoot) this.attachShadow({ mode: "open" });
      this.shadowRoot.innerHTML = `
        <style>${BASE}
          button{display:inline-flex;align-items:center;gap:6px;margin:14px 2px 0;padding:10px 16px 10px 10px;border:0;border-radius:22px;
            background:var(--card-background-color);color:var(--primary-text-color);font-size:15px;cursor:pointer}
          ha-icon{--mdc-icon-size:22px}
        </style>
        <button class="t"><ha-icon icon="mdi:chevron-left"></ha-icon>Casa</button>`;
      this.shadowRoot.querySelector("button").onclick = () => this._vai(this._c.naviga || "/lovelace/casa");
    }
  }

  const def = (n, c) => { if (!customElements.get(n)) customElements.define(n, c); };
  def("ll-strategy-dashboard-mdm-casa", MdmCasaStrategy);
  def("mdm-benvenuto", MdmBenvenuto);
  def("mdm-titolo", MdmTitolo);
  def("mdm-pulsante", MdmPulsante);
  def("mdm-indietro", MdmIndietro);
})();
