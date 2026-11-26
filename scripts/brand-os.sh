#!/usr/bin/env bash
# Applica il marchio MDM al codice del sistema operativo (cartella
# "operating-system" di Home Assistant, alla versione scelta).
#
# Uso: brand-os.sh <cartella-operating-system>
# Variabili: BRAND_NAME BRAND_OS BRAND_HOSTNAME VERSION_URL OWNER OS_BOARD
#            MDM_OTA_CERT (facoltativo: certificato per gli aggiornamenti firmati)
set -euo pipefail

OS_DIR="$1"
: "${BRAND_NAME:?}" "${BRAND_OS:?}" "${BRAND_HOSTNAME:?}" "${VERSION_URL:?}" "${OWNER:?}" "${OS_BOARD:?}"
EXT="$OS_DIR/buildroot-external"
[ -f "$EXT/meta" ] || { echo "brand-os: $OS_DIR non sembra il codice dell'OS" >&2; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== Nome del sistema e tipo di rilascio"
sed -i -E "s|^HAOS_NAME=.*|HAOS_NAME=\"${BRAND_OS}\"|" "$EXT/meta"
sed -i -E "s|^DEPLOYMENT=.*|DEPLOYMENT=\"production\"|" "$EXT/meta"

echo "== os-release (nome, sito, produttore)"
sed -i \
  -e "s|cpe:2.3:o:home-assistant:|cpe:2.3:o:mdm:|" \
  -e "s|HOME_URL=https://www.home-assistant.io/|HOME_URL=https://impianti.mdmsmart.com/|" \
  "$EXT/scripts/post-build.sh"

echo "== Nome di rete predefinito"
sed -i -E "s|^BR2_TARGET_GENERIC_HOSTNAME=.*|BR2_TARGET_GENERIC_HOSTNAME=\"${BRAND_HOSTNAME}\"|" \
  "$EXT/configs/${OS_BOARD}_defconfig"

echo "== Messaggio di benvenuto della console"
cat > "$EXT/rootfs-overlay/etc/motd" <<EOF
Benvenuto in ${BRAND_OS}.

Console riservata al tecnico MDM.
EOF

echo "== Testi visibili all'avvio (servizi, console di emergenza)"
REBRAND_EXT="sh service" BRAND_NAME="$BRAND_NAME" BRAND_OS="$BRAND_OS" \
  "$HERE/rebrand-text.sh" "$EXT/rootfs-overlay/usr/lib/systemd/system"
for f in "$EXT/rootfs-overlay/usr/sbin/haos-cli" \
         "$EXT/rootfs-overlay/usr/libexec/haos-data" \
         "$EXT/rootfs-overlay/usr/libexec/haos-freeze-hook"; do
  sed -i -e "s/Home Assistant OS/${BRAND_OS}/g" -e "s/Home Assistant/${BRAND_NAME}/g" "$f"
done

echo "== Canale aggiornamenti MDM al posto di version.home-assistant.io"
for f in "$EXT/package/hassio/hassio.mk" \
         "$EXT/package/hassio/create-data-partition.sh" \
         "$EXT/rootfs-overlay/usr/libexec/haos-apparmor" \
         "$EXT/rootfs-overlay/usr/sbin/haos-supervisor"; do
  sed -i "s|https://version.home-assistant.io/|${VERSION_URL}|g" "$f"
done

echo "== Immagini dei servizi dal registro MDM"
sed -i "s|ghcr.io/home-assistant/|ghcr.io/${OWNER}/|g" \
  "$EXT/package/hassio/dind-import-containers.sh" \
  "$EXT/rootfs-overlay/usr/sbin/haos-supervisor"

if [ -n "${MDM_OTA_CERT:-}" ] && [ -f "$MDM_OTA_CERT" ]; then
  echo "== Aggiornamenti firmati: solo con il certificato MDM"
  cp -f "$MDM_OTA_CERT" "$EXT/ota/rel-ca.pem"
  cp -f "$MDM_OTA_CERT" "$EXT/ota/dev-ca.pem"
else
  echo "== ATTENZIONE: nessun certificato MDM, aggiornamenti OS via rete non disponibili"
fi

echo "== Controllo finale"
rimasti=$(grep -rIl "version.home-assistant.io\|ghcr.io/home-assistant/" \
  "$EXT/package/hassio" "$EXT/rootfs-overlay" 2>/dev/null || true)
if [ -n "$rimasti" ]; then
  echo "brand-os: indirizzi originali ancora presenti in:" >&2
  echo "$rimasti" >&2
  exit 1
fi
echo "brand-os: completato"
