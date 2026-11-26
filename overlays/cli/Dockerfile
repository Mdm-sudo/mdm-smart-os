# Console tecnica ("ha"): banner MDM e testi dei comandi
ARG UPSTREAM
FROM ${UPSTREAM} AS originale

FROM alpine:3.22 AS lavoro
ARG BRAND_NAME
RUN apk add --no-cache bash perl grep
COPY --from=originale /usr/bin/ha /ha
COPY scripts/rebrand-binary.sh /mdm/
RUN BRAND_NAME="${BRAND_NAME}" bash /mdm/rebrand-binary.sh /ha

FROM ${UPSTREAM}
COPY --from=lavoro /ha /usr/bin/ha
COPY branding/banner.txt /etc/mdm/banner.txt
COPY overlays/cli/cli.sh /usr/bin/cli.sh
RUN chmod a+x /usr/bin/cli.sh
