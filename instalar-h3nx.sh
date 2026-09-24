#!/usr/bin/env bash
# ==============================================================================
# Instalador del cliente recomendado del servidor H3N-X (Linux/Mac)
# Descarga el pack y copia mods/config/shaderpacks dentro de tu carpeta
# .minecraft, sin tocar mods/configs que ya tengas de otros packs.
# ==============================================================================
set -euo pipefail

PACK_URL="https://raw.githubusercontent.com/h3n-x/minecraft-cliente-recomendado/main/H3NX-Cliente-Recomendado.zip"

# Default segun sistema operativo -- en Mac el launcher oficial NO usa
# ~/.minecraft (esa es la ruta de Linux), usa Application Support.
if [[ -z "${1:-}" ]]; then
    case "$(uname -s)" in
        Darwin) DEST="$HOME/Library/Application Support/minecraft" ;;
        *)      DEST="$HOME/.minecraft" ;;
    esac
else
    DEST="$1"
fi

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

echo "Descargando el cliente recomendado (~73MB)..."
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
# journeymap guarda su config en <game-directory>/journeymap/, no en config/
[[ -d "$TMP/extracted/journeymap" ]] && { mkdir -p "$DEST/journeymap"; cp -rf "$TMP/extracted/journeymap/." "$DEST/journeymap/"; }

# Los mods no hacen NADA si no existe el perfil de Fabric Loader para
# 1.21.11 -- este chequeo evita el caso real donde el script "termina bien"
# pero el juego sigue arrancando vanilla porque falta ese paso previo.
HAS_FABRIC=$(find "$DEST/versions" -maxdepth 1 -iname "fabric-loader-*-1.21.11" 2>/dev/null | head -n1 || true)

if [[ -z "$HAS_FABRIC" ]]; then
    echo
    echo "No se encontro Fabric Loader 1.21.11 -- instalandolo automaticamente..."
    # El instalador de Fabric necesita que exista launcher_profiles.json (lo
    # crea el launcher oficial la primera vez que lo abris). Si el script
    # corre ANTES de haber abierto el launcher ni una vez, ese archivo no
    # existe todavia y el instalador falla en el ultimo paso -- se crea un
    # stub minimo valido para evitarlo.
    if [[ ! -f "$DEST/launcher_profiles.json" ]]; then
        echo '{"profiles":{},"settings":{},"version":3}' > "$DEST/launcher_profiles.json"
    fi
    if command -v java >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        INSTALLER_URL=$(curl -fsSL "https://meta.fabricmc.net/v2/versions/installer" 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['url'])" 2>/dev/null || true)
        LOADER_VER=$(curl -fsSL "https://meta.fabricmc.net/v2/versions/loader" 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['version'])" 2>/dev/null || true)
        if [[ -n "$INSTALLER_URL" && -n "$LOADER_VER" ]]; then
            curl -fsSL -o "$TMP/fabric-installer.jar" "$INSTALLER_URL"
            if java -jar "$TMP/fabric-installer.jar" client -mcversion 1.21.11 -loader "$LOADER_VER" -dir "$DEST" >/dev/null 2>&1; then
                echo "Fabric Loader 1.21.11 instalado correctamente."
                HAS_FABRIC=1
            else
                echo "El instalador de Fabric fallo."
            fi
        else
            echo "No pude consultar la version mas reciente de Fabric (¿sin internet?)."
        fi
    else
        echo "Necesitas 'java' y 'python3' instalados para que lo haga automaticamente."
    fi
fi

echo
if [[ -z "$HAS_FABRIC" ]]; then
    echo "=== Copiado ✔ pero FALTA UN PASO IMPORTANTE ==="
    echo "No se pudo instalar Fabric Loader 1.21.11 automaticamente."
    echo "Los mods NO van a hacer nada hasta que lo instales vos:"
    echo "  1. Entra a https://fabricmc.net/use/installer/"
    echo "  2. Descarga el instalador, elegi Minecraft version 1.21.11"
    echo "  3. Instalalo, abri el launcher de Minecraft y elegi el nuevo perfil"
    echo "     'fabric-loader-1.21.11' antes de jugar."
else
    echo "=== Listo ✔ ==="
    echo "Fabric 1.21.11 esta instalado. Elegi el perfil 'fabric-loader-1.21.11'"
    echo "en el launcher de Minecraft y jugá."
fi
echo "Adentro del juego: Mod Menu -> FancyMenu, para asignar las imagenes"
echo "de menu (ya estan en config/fancymenu/assets/)."
echo "Al conectarte al server necesitas estar en la whitelist, y la primera"
echo "vez registrarte con: /register <contraseña> <contraseña>"
