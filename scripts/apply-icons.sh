#!/usr/bin/env bash
# Copia le icone MDM sopra quelle originali (solo i file che esistono già)
# e rigenera le versioni compresse.
#
# Uso: apply-icons.sh <cartella-icone-mdm> <cartella-static/icons>
set -euo pipefail
src="$1"; dst="$2"
[ -d "$dst" ] || { echo "apply-icons: $dst non esiste, salto"; exit 0; }

n=0
for f in "$src"/*; do
  name=$(basename "$f")
  [ -f "$dst/$name" ] || continue
  cp -f "$f" "$dst/$name"
  [ -f "$dst/$name.gz" ] && gzip -9 -n -k -f "$dst/$name"
  if [ -f "$dst/$name.br" ]; then
    if command -v brotli >/dev/null; then brotli -q 11 -f -k "$dst/$name"; else rm -f "$dst/$name.br"; fi
  fi
  n=$((n + 1))
done
echo "apply-icons: sostituite $n icone in $dst"
