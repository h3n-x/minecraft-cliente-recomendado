#!/usr/bin/env bash
# ==============================================================================
# Instalador del cliente recomendado del servidor H3N-X (Linux/Mac)
# Descarga el pack y copia mods/config/shaderpacks dentro de tu carpeta
# .minecraft, sin tocar mods/configs que ya tengas de otros packs.
# ==============================================================================
set -euo pipefail

PACK_URL="https://raw.githubusercontent.com/h3n-x/minecraft-cliente-recomendado/main/H3NX-Cliente-Recomendado.zip"
DEST="${1:-$HOME/.minecraft}"

echo "=== Instalador del cliente recomendado H3N-X ==="
echo "Destino: $DEST"
echo "(si usas Prism Launcher/MultiMC, pasa la carpeta .minecraft de tu"
echo " instancia como argumento: ./instalar-h3nx.sh /ruta/a/tu/instancia/.minecraft)"
echo

if [[ ! -d "$DEST" ]]; then
    echo "AVISO: no existe '$DEST' todavia."
    echo "¿Ya instalaste Fabric Loader para Minecraft 1.21.11 con el launcher oficial?"
    read -r -p "Crear la carpeta de todos modos? [s/N] " resp
    if [[ ! "$resp" =~ ^[sS]$ ]]; then
        echo "Cancelado. Instala Fabric primero: https://fabricmc.net/use/installer/"
        exit 1
    fi
    mkdir -p "$DEST"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Descargando el cliente recomendado (~52MB)..."
if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "$TMP/pack.zip" "$PACK_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$TMP/pack.zip" "$PACK_URL"
else
    echo "ERROR: necesitas 'curl' o 'wget' instalado para continuar." >&2
    exit 1
fi

echo "Extrayendo..."
mkdir -p "$TMP/extracted"
if command -v unzip >/dev/null 2>&1; then
    unzip -q -o "$TMP/pack.zip" -d "$TMP/extracted"
elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import zipfile; zipfile.ZipFile('$TMP/pack.zip').extractall('$TMP/extracted')"
else
    echo "ERROR: necesitas 'unzip' o 'python3' instalado para continuar." >&2
    exit 1
fi

echo "Copiando mods, config y shaderpacks a $DEST ..."
mkdir -p "$DEST/mods" "$DEST/config" "$DEST/shaderpacks"
cp -rf "$TMP/extracted/mods/." "$DEST/mods/"
cp -rf "$TMP/extracted/config/." "$DEST/config/"
cp -rf "$TMP/extracted/shaderpacks/." "$DEST/shaderpacks/"

echo
echo "=== Listo ✔ ==="
echo "1. Abri el launcher de Minecraft, elegi el perfil de Fabric Loader 1.21.11."
echo "2. Adentro del juego: Mod Menu -> FancyMenu, para asignar las imagenes"
echo "   de menu (ya estan en config/fancymenu/assets/)."
echo "3. Al conectarte al server necesitas estar en la whitelist, y la primera"
echo "   vez registrarte con: /register <contraseña> <contraseña>"
