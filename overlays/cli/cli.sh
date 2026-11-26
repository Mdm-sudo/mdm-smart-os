#!/bin/bash

# Banner MDM al posto di quello originale
cat /etc/mdm/banner.txt 2>/dev/null || true
echo

# Informazioni di sistema (indirizzi, versioni) senza il disegno originale
ha banner 2>/dev/null | sed '1,/command line interface\./d' || true

# Console interattiva
exec bash --noprofile --rcfile /etc/ha-cli/.repl_rc -i
