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
if "MDM Smart" in s:
    print("preconfig: già applicato")
    sys.exit(0)
if old not in s:
    print("preconfig: punto di aggancio non trovato in", p, file=sys.stderr)
    sys.exit(1)
p.write_text(s.replace(old, new, 1), encoding="utf8")
print("preconfig: configurazione MDM al primo avvio attivata")
