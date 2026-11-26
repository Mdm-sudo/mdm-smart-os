#!/usr/bin/env bash
# Crea il certificato con cui firmare gli aggiornamenti di MDM Smart OS.
# Da eseguire UNA volta sul tuo PC (Git Bash su Windows va bene).
# Il contenuto dei due file va messo nei segreti GitHub:
#   MDM_OTA_CERT  ← mdm-ota-cert.pem
#   MDM_OTA_KEY   ← mdm-ota-key.pem   (NON condividerlo con nessuno)
set -euo pipefail
openssl req -x509 -newkey rsa:4096 -nodes -days 7300 \
  -keyout mdm-ota-key.pem -out mdm-ota-cert.pem \
  -subj "/O=MDM Smart/CN=MDM Smart OS aggiornamenti"
chmod 600 mdm-ota-key.pem
echo "Creati mdm-ota-cert.pem e mdm-ota-key.pem."
echo "Conserva una copia della chiave in un posto sicuro: se la perdi,"
echo "gli impianti già installati non potranno più aggiornare l'OS via rete."
