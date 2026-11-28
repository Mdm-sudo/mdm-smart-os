// MDM Smart – schermata "Sto preparando il sistema" mentre si installano le app.
// Legge sensor.mdm_preparazione (scritto dall'integrazione MDM).
(() => {
  const ID = "mdm-preparazione";

  function crea() {
    const d = document.createElement("div");
    d.id = ID;
    d.setAttribute("role", "status");
    d.innerHTML = `
      <style>
        #${ID}{position:fixed;inset:0;z-index:2147483647;background:#0f0a1e;color:#f2f0fa;
          display:flex;flex-direction:column;align-items:center;justify-content:center;gap:22px;
          font-family:Roboto,Inter,system-ui,sans-serif;text-align:center;padding:24px}
        #${ID} img{width:120px;height:120px}
        #${ID} h1{margin:0;font-size:24px;font-weight:600}
        #${ID} p{margin:0;font-size:15px;color:#a9a3c4;min-height:20px}
        #${ID} .barra{width:min(420px,80vw);height:10px;border-radius:5px;background:#2c2350;overflow:hidden}
        #${ID} .barra span{display:block;height:100%;width:0;border-radius:5px;
          background:linear-gradient(90deg,#22c3a6,#8b5cf6);transition:width .6s ease}
        #${ID} small{color:#6b6585;font-size:12px}
      </style>
      <img src="/static/icons/favicon-512x512.png" alt="">
      <h1>Stiamo preparando il tuo MDM Smart</h1>
      <div class="barra"><span></span></div>
      <p class="passo"></p>
      <small>Ci vogliono alcuni minuti. Non spegnere il sistema.</small>`;
    document.body.appendChild(d);
    return d;
  }

  function aggiorna() {
    const hass = document.querySelector("home-assistant")?.hass;
    const st = hass?.states?.["sensor.mdm_preparazione"];
    let d = document.getElementById(ID);
    if (!st || st.attributes?.fatto === true) {
      if (d) d.remove();
      return;
    }
    if (!d) d = crea();
    const perc = Math.max(3, Math.min(100, Number(st.state) || 0));
    d.querySelector(".barra span").style.width = perc + "%";
    d.querySelector(".passo").textContent = st.attributes?.passo || "";
  }

  setInterval(aggiorna, 1500);
  aggiorna();
})();
