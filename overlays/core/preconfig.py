"""Al primo avvio il motore copia la configurazione MDM in /config
(tema, app, schermo intero del cliente, automazioni del cliente)."""
import pathlib
import sys

import homeassistant.config as cfg

p = pathlib.Path(cfg.__file__)
s = p.read_text(encoding="utf8")
old = '''        with open(config_path, "w", encoding="utf8") as config_file:
            config_file.write(DEFAULT_CONFIG)
'''
new = '''        import shutil as _mdm_shutil  # MDM Smart
        if os.path.isdir("/usr/share/mdm/config"):
            _mdm_shutil.copytree("/usr/share/mdm/config", config_dir, dirs_exist_ok=True)
        if not os.path.isfile(config_path):
            with open(config_path, "w", encoding="utf8") as config_file:
                config_file.write(DEFAULT_CONFIG)
'''
old2 = '''    config_path = hass.config.path(YAML_CONFIG_FILE)

    if os.path.isfile(config_path):
        return True
'''
new2 = '''    config_path = hass.config.path(YAML_CONFIG_FILE)

    if os.path.isfile(config_path):
        await hass.async_add_executor_job(_mdm_aggiorna, hass.config.config_dir)  # MDM Smart
        return True
'''
helper = '''

def _mdm_aggiorna(config_dir: str) -> None:
    """MDM Smart: ad ogni avvio aggiorna le parti MDM (non i dati del cliente)."""
    import shutil
    base = "/usr/share/mdm/config"
    for parte in ("www/mdm", "custom_components/mdm", "custom_components/scheduler"):
        sorgente = os.path.join(base, parte)
        if os.path.isdir(sorgente):
            shutil.copytree(sorgente, os.path.join(config_dir, parte), dirs_exist_ok=True)
    for parte in ("themes/mdm.yaml",):
        sorgente = os.path.join(base, parte)
        if os.path.isfile(sorgente):
            os.makedirs(os.path.dirname(os.path.join(config_dir, parte)), exist_ok=True)
            shutil.copyfile(sorgente, os.path.join(config_dir, parte))


async def async_ensure_config_exists('''
if "MDM Smart" in s:
    print("preconfig: già applicato")
    sys.exit(0)
if old not in s:
    print("preconfig: punto di aggancio non trovato in", p, file=sys.stderr)
    sys.exit(1)
if old2 not in s:
    print("preconfig: aggancio aggiornamento non trovato", file=sys.stderr)
    sys.exit(1)
s = s.replace(old, new, 1).replace(old2, new2, 1)
s = s.replace("\n\nasync def async_ensure_config_exists(", helper, 1)
p.write_text(s, encoding="utf8")
print("preconfig: configurazione MDM al primo avvio attivata")
