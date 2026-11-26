# Supervisor: legge gli aggiornamenti dal canale MDM e usa le immagini MDM
ARG UPSTREAM
FROM ${UPSTREAM}

ARG OWNER
ARG VERSION_URL

RUN set -eu; \
    SUP=$(python3 -c 'import supervisor, os; print(os.path.dirname(supervisor.__file__))'); \
    sed -i \
      -e "s|https://version.home-assistant.io/|${VERSION_URL}|g" \
      "$SUP/const.py"; \
    sed -i "s|ghcr.io/home-assistant/|ghcr.io/${OWNER}/|g" \
      "$SUP/supervisor.py" \
      "$SUP/plugins/base.py" \
      "$SUP/homeassistant/module.py"; \
    if grep -q "version.home-assistant.io" "$SUP/const.py"; then echo "URL non sostituito" >&2; exit 1; fi; \
    python3 -m compileall -q "$SUP/const.py" "$SUP/supervisor.py" "$SUP/plugins/base.py" "$SUP/homeassistant/module.py"
