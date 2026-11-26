#!/usr/bin/env bash
# Sostituisce il marchio nei file di testo (js, json, html, svg, ...) delle
# cartelle indicate e rigenera le versioni compresse .gz/.br accanto ai file.
#
# Uso: rebrand-text.sh <cartella> [cartella...]
# Variabili: BRAND_NAME, BRAND_OS  (da branding/brand.env)
#            REBRAND_EXT  estensioni da trattare (facoltativo)
set -euo pipefail

: "${BRAND_NAME:?manca BRAND_NAME}"
: "${BRAND_OS:?manca BRAND_OS}"
EXT="${REBRAND_EXT:-js mjs json html htm svg txt xml webmanifest}"

# Sito dove finiscono tutti i link di aiuto e documentazione
HELP_HOST="${BRAND_HELP_HOST:-assistenza.mdmsmart.com}"

# Ordine importante: prima le frasi lunghe, poi il nome semplice
SED_EXPR=(
  -e "s/Home Assistant Operating System/${BRAND_OS}/g"
  -e "s/Home Assistant OS/${BRAND_OS}/g"
  -e "s/Home Assistant/${BRAND_NAME}/g"
  -e "s/Open Home Foundation/MDM Smart/g"
)

# Link di aiuto, documentazione, forum, sorgenti -> sito MDM.
# Restano solo gli indirizzi tecnici che servono a far funzionare il sistema
# (icone delle integrazioni "brands." e collegamenti account "my.").
LINK_EXPR='
  s/\$\{[^{}]*"www"\}\.home-assistant\.io/$ENV{HELP_HOST}/g;
  s#https?://(www|rc|next|community|companion|developers|demo|data)\.home-assistant\.io#https://$ENV{HELP_HOST}#g;
  s#://www\.home-assistant\.io#://$ENV{HELP_HOST}#g;
  s#https?://github\.com/home-assistant[^"'"'"'`\s)<]*#https://$ENV{HELP_HOST}#g;
'
TRACCE='Home Assistant|Open Home Foundation|(www|rc|next|community|companion|developers|demo|data)\.home-assistant\.io|"www"\}\.home-assistant\.io|github\.com/home-assistant'

name_args=()
for e in $EXT; do
  [ ${#name_args[@]} -gt 0 ] && name_args+=(-o)
  name_args+=(-name "*.${e}")
done

totale=0
for dir in "$@"; do
  [ -d "$dir" ] || { echo "rebrand-text: cartella mancante: $dir" >&2; exit 1; }
  while IFS= read -r -d '' f; do
    grep -qE "$TRACCE" "$f" || continue
    sed -i "${SED_EXPR[@]}" "$f"
    HELP_HOST="$HELP_HOST" perl -pi -e "$LINK_EXPR" "$f"
    totale=$((totale + 1))
    # Home Assistant serve i file già compressi se esistono: vanno rifatti
    if [ -f "$f.gz" ]; then gzip -9 -n -k -f "$f"; fi
    if [ -f "$f.br" ]; then
      if command -v brotli >/dev/null; then brotli -q 11 -f -k "$f"; else rm -f "$f.br"; fi
    fi
  done < <(find "$dir" -type f \( "${name_args[@]}" \) ! -name "*.map" -print0)
done
echo "rebrand-text: modificati $totale file"
