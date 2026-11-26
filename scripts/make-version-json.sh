#!/usr/bin/env bash
# Crea il file del canale aggiornamenti MDM partendo da quello ufficiale.
# Le versioni restano le stesse, cambiano gli indirizzi delle immagini
# e degli aggiornamenti del sistema operativo.
#
# Uso: make-version-json.sh <stable.json originale> <file uscita>
# Variabili: OWNER REPO OS_VERSION (facoltativa) MACHINE
set -euo pipefail
in="$1"; out="$2"
: "${OWNER:?}" "${REPO:?}" "${MACHINE:?}"

jq --arg owner "$OWNER" --arg repo "$REPO" --arg osv "${OS_VERSION:-}" --arg machine "$MACHINE" '
  .images |= map_values(sub("ghcr.io/home-assistant/"; "ghcr.io/\($owner)/"))
  | .ota = "https://github.com/\($owner)/\($repo)/releases/download/{version}/{os_name}_{board}-{version}.raucb"
  | .hassos = (if $osv == "" then {} else {($machine): $osv} end)
  | .["hassos-upgrade"] = {}
' "$in" > "$out"

# Controlli
jq -e '.channel == "stable" and (.supervisor|length>0) and (.images.core|test("ghcr.io/"))' "$out" >/dev/null
if grep -q "ghcr.io/home-assistant/" "$out"; then echo "immagini originali ancora presenti" >&2; exit 1; fi
echo "make-version-json: creato $out"
