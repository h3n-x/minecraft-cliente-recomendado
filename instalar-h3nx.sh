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

echo "Descargando el cliente recomendado (~75MB)..."
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

echo "Copiando mods, config, shaderpacks y resourcepacks a $DEST ..."
mkdir -p "$DEST/mods" "$DEST/config" "$DEST/shaderpacks" "$DEST/resourcepacks"
cp -rf "$TMP/extracted/mods/." "$DEST/mods/"
cp -rf "$TMP/extracted/config/." "$DEST/config/"
cp -rf "$TMP/extracted/shaderpacks/." "$DEST/shaderpacks/"
[[ -d "$TMP/extracted/resourcepacks" ]] && cp -rf "$TMP/extracted/resourcepacks/." "$DEST/resourcepacks/"

# Los mods no hacen NADA si no existe el perfil de Fabric Loader para
# 1.21.11 -- este chequeo evita el caso real donde el script "termina bien"
# pero el juego sigue arrancando vanilla porque falta ese paso previo.
HAS_FABRIC=$(find "$DEST/versions" -maxdepth 1 -iname "fabric-loader-*-1.21.11" 2>/dev/null | head -n1 || true)

echo
if [[ -z "$HAS_FABRIC" ]]; then
    echo "=== Copiado ✔ pero FALTA UN PASO IMPORTANTE ==="
    echo "No encontre un perfil de Fabric Loader para 1.21.11 instalado."
    echo "Los mods NO van a hacer nada hasta que instales Fabric para esa version:"
    echo "  1. Entra a https://fabricmc.net/use/installer/"
    echo "  2. Descarga el instalador, elegi Minecraft version 1.21.11"
    echo "  3. Instalalo, abri el launcher de Minecraft y elegi el nuevo perfil"
    echo "     'fabric-loader-1.21.11' antes de jugar."
else
    echo "=== Listo ✔ ==="
    echo "Ya tenes Fabric 1.21.11 instalado. Elegi el perfil 'fabric-loader-1.21.11'"
    echo "en el launcher de Minecraft y jugá."
fi
echo "Adentro del juego: Mod Menu -> FancyMenu, para asignar las imagenes"
echo "de menu (ya estan en config/fancymenu/assets/)."
echo "Al conectarte al server necesitas estar en la whitelist, y la primera"
echo "vez registrarte con: /register <contraseña> <contraseña>"
