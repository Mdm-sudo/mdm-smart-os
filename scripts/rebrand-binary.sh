#!/usr/bin/env bash
# Sostituisce "Home Assistant" dentro un programma già compilato.
# Funziona solo se il nuovo nome ha la stessa lunghezza (14 caratteri),
# così le posizioni dei dati nel file non cambiano.
#
# Uso: rebrand-binary.sh <file>
set -euo pipefail
: "${BRAND_NAME:?manca BRAND_NAME}"
f="$1"

if [ "${#BRAND_NAME}" -ne 14 ]; then
  echo "rebrand-binary: BRAND_NAME deve essere lungo 14 caratteri (ora ${#BRAND_NAME})" >&2
  exit 1
fi

prima=$(grep -c -a -o "Home Assistant" "$f" || true)
OLD="Home Assistant" NEW="$BRAND_NAME" perl -0777 -pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$f"
dopo=$(grep -c -a -o "Home Assistant" "$f" || true)
echo "rebrand-binary: $f – sostituzioni: $prima, rimaste: $dopo"
[ "$dopo" -eq 0 ]
