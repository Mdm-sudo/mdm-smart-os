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
echo "solo-caricamento: modificati $n file"
