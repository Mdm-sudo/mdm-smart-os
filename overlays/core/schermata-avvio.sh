#!/usr/bin/env bash
# Schermata di caricamento MDM: sfondo scuro, logo MDM, niente marchi altrui.
set -euo pipefail
FRONTEND="$1"
for f in "$FRONTEND/index.html" "$FRONTEND/authorize.html" "$FRONTEND/onboarding.html"; do
  [ -f "$f" ] || continue
  perl -0pi -e '
    # logo originale (svg in linea) -> logo MDM
    s#(<div id="ha-launch-screen"><div class="ha-launch-screen-spacer-top"></div>)<svg[^>]*>.*?</svg>#$1<img src="/static/icons/favicon-512x512.png" alt="MDM Smart" width="140" height="140">#s;
    # riquadro "progetto della Open Home Foundation" -> via
    s#<div class="ohf-logo">.*?</div>##gs;
    # sfondo scuro MDM su tutte le pagine di avvio e accesso
    s#</head>#<style>html,body,\#ha-launch-screen{background-color:\#0f0a1e!important;color:\#f2f0fa}\#ha-launch-screen img{display:block;margin:0 auto}</style></head>#;
  ' "$f"
  [ -f "$f.gz" ] && gzip -9 -n -k -f "$f"
  if [ -f "$f.br" ]; then
    if command -v brotli >/dev/null; then brotli -q 11 -f -k "$f"; else rm -f "$f.br"; fi
  fi
done
grep -q "ha-launch-screen" "$FRONTEND/index.html" && ! grep -q "ohf-badge" "$FRONTEND/index.html"
echo "schermata-avvio: logo MDM e sfondo scuro applicati"
