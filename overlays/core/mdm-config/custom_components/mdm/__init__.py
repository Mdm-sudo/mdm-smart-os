"""MDM Smart: configurazione automatica al primo avvio.

- tema scuro MDM come predefinito
- app installate e avviate: Mosquitto, Node-RED, Zigbee2MQTT, Cloudflared,
  Matter Hub (Alexa e Google in locale)
- coordinatore Zigbee trovato da solo; secondo coordinatore con un servizio
- "Le mie automazioni" del cliente (Scheduler) attivato
"""
from __future__ import annotations

import asyncio
import logging
import os
import secrets
from typing import Any

import aiohttp

from homeassistant.components import persistent_notification
from homeassistant.const import EVENT_HOMEASSISTANT_STARTED
from homeassistant.core import CoreState, HomeAssistant, ServiceCall, callback
from homeassistant.helpers.aiohttp_client import async_get_clientsession
from homeassistant.helpers.storage import Store
from homeassistant.helpers.typing import ConfigType

_LOGGER = logging.getLogger(__name__)
DOMAIN = "mdm"
NOTIFICA = "mdm_configurazione"

REPOSITORY = [
    "https://github.com/hassio-addons/repository",
    "https://github.com/zigbee2mqtt/hassio-zigbee2mqtt",
    "https://github.com/brenner-tobias/ha-addons",
    "https://github.com/t0bst4r/home-assistant-addons",
]

# (fine dello slug, nome mostrato, avviare subito)
APP = [
    ("core_mosquitto", "Mosquitto (MQTT)", True),
    ("_nodered", "Node-RED", True),
    ("_zigbee2mqtt", "Zigbee2MQTT", None),  # parte solo se trova il coordinatore
    ("_hamh", "Alexa e Google (Matter Hub)", True),
    ("_cloudflared", "Accesso remoto (Cloudflared)", False),  # serve il token
]

COORDINATORI = ("sonoff", "slzb", "skyconnect", "zbt", "conbee", "zigstar", "cc2652", "cc1352", "ember", "zigbee", "itead", "dresden")


class Supervisor:
    def __init__(self, hass: HomeAssistant) -> None:
        self._s = async_get_clientsession(hass)
        self._url = f"http://{os.environ.get('SUPERVISOR', 'supervisor')}"
        self._h = {"Authorization": f"Bearer {os.environ.get('SUPERVISOR_TOKEN', '')}"}

    async def get(self, path: str) -> Any:
        async with self._s.get(self._url + path, headers=self._h, timeout=aiohttp.ClientTimeout(total=120)) as r:
            d = await r.json(content_type=None)
            if d.get("result") != "ok":
                raise RuntimeError(f"GET {path}: {d.get('message')}")
            return d.get("data")

    async def post(self, path: str, data: dict | None = None, timeout: int = 120) -> Any:
        async with self._s.post(self._url + path, headers=self._h, json=data or {}, timeout=aiohttp.ClientTimeout(total=timeout)) as r:
            d = await r.json(content_type=None)
            if d.get("result") != "ok":
                raise RuntimeError(f"POST {path}: {d.get('message')}")
            return d.get("data")


async def async_setup(hass: HomeAssistant, config: ConfigType) -> bool:
    store: Store = Store(hass, 1, "mdm_setup")

    async def avvia(_event=None) -> None:
        hass.async_create_background_task(_configura(hass, store), "mdm_configurazione")

    if hass.state is CoreState.running:
        await avvia()
    else:
        hass.bus.async_listen_once(EVENT_HOMEASSISTANT_STARTED, avvia)

    async def servizio_coordinatore(call: ServiceCall) -> None:
        await _secondo_coordinatore(hass, call.data.get("porta"), call.data.get("tipo"))

    async def servizio_riconfigura(call: ServiceCall) -> None:
        await store.async_save({})
        await _configura(hass, store)

    hass.services.async_register(DOMAIN, "aggiungi_coordinatore_zigbee", servizio_coordinatore)
    hass.services.async_register(DOMAIN, "riconfigura", servizio_riconfigura)
    return True


def _avvisa(hass: HomeAssistant, testo: str) -> None:
    """Avviso solo per problemi (visibile al tecnico)."""
    persistent_notification.async_create(hass, testo, title="MDM Smart", notification_id=NOTIFICA)


def _avanzamento(hass: HomeAssistant, perc: int, passo: str, fatto: bool = False) -> None:
    """Stato letto dalla schermata di caricamento MDM."""
    hass.states.async_set(
        "sensor.mdm_preparazione", perc,
        {"passo": passo, "fatto": fatto, "unit_of_measurement": "%", "friendly_name": "Preparazione MDM", "icon": "mdi:progress-wrench"},
    )


async def _configura(hass: HomeAssistant, store: Store) -> None:
    stato: dict = await store.async_load() or {}

    # Pagina iniziale "Casa" per tutti, niente "Panoramica" standard
    try:
        await _imposta_pagine(hass)
    except Exception as err:  # noqa: BLE001
        _LOGGER.warning("Pagine MDM non impostate: %s", err)

    # Tema scuro MDM per tutti (anche se la configurazione è già fatta)
    try:
        # Sempre scuro: MDM sia come tema chiaro sia come tema scuro
        await hass.services.async_call("frontend", "set_theme", {"name": "MDM"}, blocking=True)
        await hass.services.async_call("frontend", "set_theme", {"name": "MDM", "mode": "dark"}, blocking=True)
    except Exception as err:  # noqa: BLE001
        _LOGGER.warning("Tema MDM non impostato: %s", err)

    await _attiva_automazioni_cliente(hass)

    if stato.get("fatto"):
        _avanzamento(hass, 100, "Pronto", True)
        return
    if "SUPERVISOR_TOKEN" not in os.environ:
        _LOGGER.warning("Supervisor non disponibile: installazione app saltata")
        _avanzamento(hass, 100, "Pronto", True)
        return

    sup = Supervisor(hass)
    _avanzamento(hass, 5, "Preparo l'archivio delle app")
    esiti: list[str] = []
    problemi: list[str] = []

    for repo in REPOSITORY:
        try:
            await sup.post("/store/repositories", {"repository": repo})
        except RuntimeError as err:
            _LOGGER.debug("Repository %s: %s", repo, err)
    try:
        await sup.post("/store/reload", timeout=300)
    except RuntimeError as err:
        _LOGGER.warning("Aggiornamento store: %s", err)

    negozio = await sup.get("/store")
    disponibili = [a["slug"] for a in negozio.get("addons", [])]

    for i, (fine, nome, avvia) in enumerate(APP):
        _avanzamento(hass, 15 + i * 80 // len(APP), f"Installo {nome}")
        slug = next((s for s in disponibili if s == fine or s.endswith(fine)), None)
        if not slug:
            problemi.append(f"✗ {nome}: non trovata")
            continue
        try:
            info = await sup.get(f"/addons/{slug}/info")
            if not info.get("version"):
                await sup.post(f"/store/addons/{slug}/install", timeout=1800)
                info = await sup.get(f"/addons/{slug}/info")
            opzioni = dict(info.get("options") or {})
            parti = avvia

            if fine == "_nodered":
                opzioni.setdefault("credential_secret", secrets.token_hex(16))
                if not opzioni.get("credential_secret"):
                    opzioni["credential_secret"] = secrets.token_hex(16)
                opzioni["ssl"] = False
            if fine == "_zigbee2mqtt":
                porte = await _porte_zigbee(sup)
                if porte:
                    opzioni["serial"] = {**(opzioni.get("serial") or {}), "port": porte[0]}
                    parti = True
                else:
                    parti = False

            await sup.post(f"/addons/{slug}/options", {"options": opzioni, "boot": "auto" if parti else "manual", "watchdog": True})
            if parti and info.get("state") != "started":
                await sup.post(f"/addons/{slug}/start", timeout=600)
            esiti.append(f"✓ {nome}")
        except Exception as err:  # noqa: BLE001
            _LOGGER.exception("App %s", nome)
            problemi.append(f"✗ {nome}: {err}")

    await store.async_save({"fatto": True})
    _avanzamento(hass, 100, "Pronto", True)
    _LOGGER.info("Configurazione MDM completata: %s", ", ".join(esiti))
    if problemi:
        _avvisa(hass, "Configurazione MDM: alcune app non si sono installate.\n\n" + "\n".join(problemi))


async def _porte_zigbee(sup: Supervisor) -> list[str]:
    try:
        hw = await sup.get("/hardware/info")
    except RuntimeError:
        return []
    porte = []
    for dev in hw.get("devices", []):
        by_id = dev.get("by_id") or ""
        if dev.get("subsystem") == "tty" and by_id and any(k in by_id.lower() for k in COORDINATORI):
            porte.append(by_id)
    return sorted(porte)


async def _secondo_coordinatore(hass: HomeAssistant, porta: str | None, tipo: str | None) -> None:
    """Seconda rete Zigbee: una seconda istanza di Zigbee2MQTT (versione Edge)."""
    sup = Supervisor(hass)
    negozio = await sup.get("/store")
    slug = next((a["slug"] for a in negozio.get("addons", []) if a["slug"].endswith("_zigbee2mqtt_edge")), None)
    if not slug:
        _avvisa(hass, "Secondo coordinatore: app Zigbee2MQTT Edge non trovata.")
        return
    if not porta:
        porte = await _porte_zigbee(sup)
        porta = porte[1] if len(porte) > 1 else None
    if not porta:
        _avvisa(hass, "Secondo coordinatore: non trovo una seconda chiavetta Zigbee collegata.")
        return
    info = await sup.get(f"/addons/{slug}/info")
    if not info.get("version"):
        await sup.post(f"/store/addons/{slug}/install", timeout=1800)
        info = await sup.get(f"/addons/{slug}/info")
    opzioni = dict(info.get("options") or {})
    opzioni["data_path"] = "/config/zigbee2mqtt2"
    opzioni["mqtt"] = {**(opzioni.get("mqtt") or {}), "base_topic": "zigbee2mqtt2"}
    opzioni["serial"] = {"port": porta, **({"adapter": tipo} if tipo else {})}
    await sup.post(f"/addons/{slug}/options", {"options": opzioni, "boot": "auto", "watchdog": True})
    await sup.post(f"/addons/{slug}/start", timeout=600)
    _avvisa(hass, f"Seconda rete Zigbee attiva sulla chiavetta {porta}.")


async def _attiva_automazioni_cliente(hass: HomeAssistant) -> None:
    """Attiva lo Scheduler, usato dalla pagina 'Le mie automazioni' del cliente."""
    if hass.config_entries.async_entries("scheduler"):
        return
    try:
        res = await hass.config_entries.flow.async_init("scheduler", context={"source": "user"})
        if res.get("type") == "form":
            await hass.config_entries.flow.async_configure(res["flow_id"], {})
    except Exception as err:  # noqa: BLE001
        _LOGGER.warning("Automazioni cliente non attivate: %s", err)


# Pagine del menu: (titolo, icona, solo tecnico, visibile nel menu)
PAGINE: dict[str, dict[str, Any]] = {
    "lovelace": {"title": "Casa", "icon": "mdi:home-variant", "show_in_sidebar": True},
    "home": {"show_in_sidebar": False, "require_admin": True},
    "map": {"require_admin": True},
    "energy": {"require_admin": True},
    "logbook": {"require_admin": True},
    "history": {"require_admin": True},
    "media-browser": {"require_admin": True},
    "todo": {"require_admin": True},
}


async def _imposta_pagine(hass: HomeAssistant) -> None:
    """La pagina MDM "Casa" è la pagina iniziale di tutti gli utenti."""
    from homeassistant.components.frontend import (
        DATA_PANELS,
        DATA_PANELS_CONFIG,
        DATA_PANELS_STORE,
    )
    from homeassistant.components.frontend.storage import async_system_store
    from homeassistant.const import EVENT_PANELS_UPDATED

    pannelli = hass.data.get(DATA_PANELS, {})
    config = hass.data[DATA_PANELS_CONFIG]
    cambiato = False
    for url, voluto in PAGINE.items():
        if url not in pannelli:
            continue
        attuale = dict(config.get(url, {}))
        nuovo = {**attuale, **voluto}
        if nuovo != attuale:
            config[url] = nuovo
            cambiato = True
    if cambiato:
        hass.data[DATA_PANELS_STORE].async_delay_save(lambda: hass.data[DATA_PANELS_CONFIG], 1)
        hass.bus.async_fire(EVENT_PANELS_UPDATED)

    sistema = await async_system_store(hass)

    @callback
    def _controlla() -> None:
        # la creazione del primo utente riscrive questi dati: rimetto "Casa"
        core = dict(sistema.data.get("core") or {})
        if core.get("default_panel") != "lovelace":
            core["default_panel"] = "lovelace"
            hass.async_create_task(sistema.async_set_item("core", core))

    _controlla()
    if not hass.data.get("mdm_pagina_iniziale"):
        hass.data["mdm_pagina_iniziale"] = True
        sistema.async_subscribe("core", _controlla)
