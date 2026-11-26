# Pagina di controllo dello stato (porta 4357)
ARG UPSTREAM
FROM ${UPSTREAM} AS originale

FROM alpine:3.22 AS lavoro
ARG BRAND_NAME
ARG BRAND_OS
RUN apk add --no-cache bash perl
COPY --from=originale /usr/share/www /www
COPY scripts/rebrand-text.sh /mdm/
RUN BRAND_NAME="${BRAND_NAME}" BRAND_OS="${BRAND_OS}" bash /mdm/rebrand-text.sh /www

FROM ${UPSTREAM}
COPY --from=lavoro /www /usr/share/www
