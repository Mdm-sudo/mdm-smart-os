# Pagina "sto preparando il sistema" mostrata al primo avvio.
# L'immagine originale non ha una shell: si lavora in una copia e si
# rimettono solo i file modificati.
ARG UPSTREAM
FROM ${UPSTREAM} AS originale

FROM alpine:3.22 AS lavoro
ARG BRAND_NAME
ARG BRAND_OS
RUN apk add --no-cache bash brotli perl
COPY --from=originale /usr/share/www /www
COPY scripts/rebrand-text.sh scripts/apply-icons.sh overlays/landingpage/solo-caricamento.sh overlays/scuro.css /mdm/
COPY build/icons/ /mdm/icons/
RUN BRAND_NAME="${BRAND_NAME}" BRAND_OS="${BRAND_OS}" bash /mdm/rebrand-text.sh /www \
 && bash /mdm/apply-icons.sh /mdm/icons /www/static/icons \
 && bash /mdm/solo-caricamento.sh /www

FROM ${UPSTREAM}
COPY --from=lavoro /www /usr/share/www
