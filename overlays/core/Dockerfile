# Interfaccia e motore con il marchio MDM.
# Parte dall'immagine originale della stessa versione e cambia solo
# testi, icone e nome dell'app: il resto resta identico (aggiornabile).
ARG UPSTREAM
FROM ${UPSTREAM}

ARG BRAND_NAME
ARG BRAND_OS

COPY scripts/rebrand-text.sh scripts/apply-icons.sh /tmp/mdm/
COPY build/icons/ /tmp/mdm/icons/
COPY overlays/core/rebrand-core.sh overlays/core/schermata-avvio.sh overlays/core/preconfig.py overlays/scuro.css /tmp/mdm/
COPY overlays/core/mdm-config/ /usr/share/mdm/config/

RUN set -eu; \
    apk add --no-cache --virtual .mdm-build brotli bash perl; \
    BRAND_NAME="${BRAND_NAME}" BRAND_OS="${BRAND_OS}" bash /tmp/mdm/rebrand-core.sh; \
    apk del .mdm-build; \
    rm -rf /tmp/mdm
