#!/usr/bin/env bash
# Crea tutte le icone dell'interfaccia partendo da branding/logo.png
# (quadrato, almeno 1024x1024, sfondo trasparente o pieno).
#
# Uso: make-icons.sh <logo.png> <cartella-uscita>
set -euo pipefail
logo="$1"; out="$2"
mkdir -p "$out"

if command -v magick >/dev/null; then IM=(magick); else IM=(convert); fi

quadrato() { "${IM[@]}" "$logo" -background none -gravity center -resize "${1}x${1}" -extent "${1}x${1}" "$2"; }

for s in 16 32 192 384 512 1024; do quadrato "$s" "$out/favicon-${s}x${s}.png"; done
quadrato 180 "$out/favicon-apple-180x180.png"
"${IM[@]}" "$logo" -background none -resize 256x256 -define icon:auto-resize=256,64,48,32,16 "$out/favicon.ico"

# Icone "maskable" (Android): logo più piccolo al centro, con margine
for s in 48 72 96 128 192 384 512; do
  inner=$(( s * 70 / 100 ))
  "${IM[@]}" "$logo" -background none -resize "${inner}x${inner}" -gravity center \
    -background "#1a1033" -extent "${s}x${s}" "$out/maskable_icon-${s}x${s}.png"
done

# Riquadri Windows
for wh in 70x70 150x150 310x310 310x150; do
  h=${wh#*x}
  "${IM[@]}" "$logo" -background none -resize "x$(( h * 80 / 100 ))" -gravity center \
    -background none -extent "$wh" "$out/tile-win-${wh}.png"
done

# SVG che contiene il logo (sostituisce i loghi originali in formato svg)
b64=$(base64 -w0 "$out/favicon-512x512.png")
svg="<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 512 512\"><image width=\"512\" height=\"512\" xlink:href=\"data:image/png;base64,${b64}\"/></svg>"
for n in mask-icon.svg ohf.svg logo_ohf.svg; do printf '%s' "$svg" > "$out/$n"; done

echo "make-icons: create $(ls "$out" | wc -l) icone in $out"
