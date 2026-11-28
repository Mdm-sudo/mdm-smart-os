#!/usr/bin/env bash
# Schermata di caricamento MDM: sfondo scuro, logo MDM, niente marchi altrui.
set -euo pipefail
FRONTEND="$1"
for f in "$FRONTEND/index.html" "$FRONTEND/authorize.html" "$FRONTEND/onboarding.html"; do
  [ -f "$f" ] || continue
  perl -0pi -e '
    # logo originale (svg in linea) -> logo MDM
    s#(<div id="ha-launch-screen".*?)<svg\b.*?</svg>#$1<img src="/static/icons/favicon-512x512.png" alt="MDM Smart" width="140" height="140">#s;
    # logo originale (immagine) -> logo MDM
    s#<img class="ha-logo"[^>]*>#<img class="ha-logo" src="/static/icons/favicon-512x512.png" alt="MDM Smart" width="140" height="140">#g;
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
# Tutti i loghi originali (file svg) diventano il logo MDM, ovunque compaiano
LOGO_B64="$(base64 -w0 "$FRONTEND/static/icons/favicon-512x512.png")"
n=0
for f in "$FRONTEND"/static/images/home-assistant-logo*.svg "$FRONTEND"/static/images/open-home-foundation*.svg; do
  [ -f "$f" ] || continue
  case "$f" in
    *open-home-foundation*) printf '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>' > "$f" ;;
    *) printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 512 512"><image width="512" height="512" xlink:href="data:image/png;base64,%s"/></svg>' "$LOGO_B64" > "$f" ;;
  esac
  rm -f "$f.gz" "$f.br"
  gzip -9 -n -k -f "$f"
  command -v brotli >/dev/null && brotli -q 11 -f -k "$f"
  n=$((n + 1))
done
echo "schermata-avvio: loghi originali sostituiti: $n"

CSS="$(cat /tmp/mdm/scuro.css)"
for f in "$FRONTEND/authorize.html" "$FRONTEND/onboarding.html"; do
  [ -f "$f" ] || continue
  CSS="$CSS" perl -0pi -e 's#</head>#<style>$ENV{CSS}</style></head>#' "$f"
  [ -f "$f.gz" ] && gzip -9 -n -k -f "$f"
  if [ -f "$f.br" ]; then
    if command -v brotli >/dev/null; then brotli -q 11 -f -k "$f"; else rm -f "$f.br"; fi
  fi
done
grep -q "ha-launch-screen" "$FRONTEND/index.html"
echo "schermata-avvio: svg rimasti in index.html: $(grep -o '<svg' "$FRONTEND/index.html" | wc -l), logo MDM: $(grep -o 'alt="MDM Smart"' "$FRONTEND/index.html" | wc -l), logo originale: $(grep -o 'home-assistant-logo' "$FRONTEND/index.html" | wc -l)"
if grep -q '<svg\|home-assistant-logo\|alt="Home Assistant"' "$FRONTEND/index.html"; then echo "ATTENZIONE: logo originale ancora presente" >&2; exit 1; fi
echo "schermata-avvio: logo MDM e sfondo scuro applicati"
