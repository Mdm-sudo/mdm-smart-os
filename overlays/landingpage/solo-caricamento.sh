#!/usr/bin/env bash
# Pagina di primo avvio: resta solo il caricamento.
# Toglie i riquadri sotto (visione, comunità, app...) e la riga in fondo
# (scelta lingua e link di aiuto).
set -euo pipefail
WWW="$1"
n=0
while IFS= read -r -d '' f; do
  grep -q "onboarding-welcome-links" "$f" || continue
  perl -0pi -e '
    s#<onboarding-welcome-links[^>]*>\s*</onboarding-welcome-links>##g;
    s#<div class="footer">.*?</div>##gs;
  ' "$f"
  [ -f "$f.gz" ] && gzip -9 -n -k -f "$f"
  if [ -f "$f.br" ]; then
    if command -v brotli >/dev/null; then brotli -q 11 -f -k "$f"; else rm -f "$f.br"; fi
  fi
  n=$((n + 1))
done < <(find "$WWW" -name "*.js" ! -name "*.map" -print0)
# Sfondo e riquadri scuri MDM
CSS="$(cat /mdm/scuro.css)"
for h in "$WWW/index.html"; do
  CSS="$CSS" perl -0pi -e 's#</head>#<style>$ENV{CSS}</style></head>#' "$h"
  [ -f "$h.gz" ] && gzip -9 -n -k -f "$h"
  if [ -f "$h.br" ]; then
    if command -v brotli >/dev/null; then brotli -q 11 -f -k "$h"; else rm -f "$h.br"; fi
  fi
done
grep -q "0f0a1e" "$WWW/index.html"
echo "solo-caricamento: modificati $n file, tema scuro applicato"
