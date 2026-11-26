#!/usr/bin/env bash
# Eseguito dentro l'immagine del motore durante la creazione.
set -euo pipefail
: "${BRAND_NAME:?}" "${BRAND_OS:?}"

PY=$(command -v python3)
FRONTEND=$("$PY" -c 'import hass_frontend, os; print(os.path.dirname(hass_frontend.__file__))')
CORE=$("$PY" -c 'import homeassistant, os; print(os.path.dirname(homeassistant.__file__))')
echo "Interfaccia: $FRONTEND"
echo "Motore:      $CORE"

# 1) Interfaccia web: tutti i testi, pagine di login e primo avvio
bash /tmp/mdm/rebrand-text.sh "$FRONTEND"

# 2) Icone e loghi
bash /tmp/mdm/apply-icons.sh /tmp/mdm/icons "$FRONTEND/static/icons"

# 3) Motore: traduzioni e nomi mostrati nell'interfaccia (solo file JSON,
#    il codice Python non viene toccato per non rompere il funzionamento)
REBRAND_EXT="json" bash /tmp/mdm/rebrand-text.sh "$CORE"

# 3b) Niente servizi esterni di Home Assistant attivati di serie:
#     cloud Nabu Casa e avvisi dal sito di Home Assistant
"$PY" - "$CORE/components/default_config/manifest.json" <<'PYEOF'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m["dependencies"] = [d for d in m["dependencies"] if d not in ("cloud", "homeassistant_alerts")]
json.dump(m, open(p, "w"), indent=2)
print("default_config senza cloud e avvisi esterni")
PYEOF

# 4) Nome dell'app installabile (titolo scheda, icona sul telefono)
sed -i -e "s/\"Home Assistant\"/\"${BRAND_NAME}\"/g" "$CORE/components/frontend/__init__.py"

# 5) Ricompila la cache Python del file modificato
"$PY" -m compileall -q "$CORE/components/frontend/__init__.py" || true

echo "Marchio MDM applicato."
