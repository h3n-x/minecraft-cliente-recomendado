#!/usr/bin/env bash
# Instalador automatico del cliente H3N-X (Arclight + Forge 1.20.1) para Linux.
# - Instala Forge 1.20.1-47.4.10 si no esta presente (instalador oficial en
#   modo headless, sin abrir ninguna ventana).
# - Descarga el pack de mods/resourcepacks/shaders/config desde el ultimo
#   Release de este repo, en una carpeta de juego propia (no toca tu
#   .minecraft normal ni tus otras instalaciones de Fabric).
# - Crea/actualiza el perfil "H3N-X (Arclight)" en el launcher oficial.
#
# Uso: bash instalar-h3nx.sh
set -euo pipefail

FORGE_VERSION="1.20.1-47.4.10"
MC_DIR="${HOME}/.minecraft"
GAME_DIR="${HOME}/.minecraft-arclight-h3nx"
REPO_API="https://api.github.com/repos/h3n-x/minecraft-cliente-recomendado/releases/latest"
SERVER_ADDRESS="laurel-wants.tun.ply.gg"

step() { echo -e "\033[36m==> $1\033[0m"; }
ok()   { echo -e "\033[32m    $1\033[0m"; }
warn() { echo -e "\033[33m    $1\033[0m"; }

# --- 1. Dependencias ---
step "Verificando dependencias (java, curl, python3)..."
for bin in java curl python3; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        warn "Falta '$bin'."
        if [[ "$bin" == "java" ]]; then
            warn "Instala el launcher oficial de Minecraft (https://www.minecraft.net/download)"
            warn "y abrilo al menos una vez -- trae su propio Java. O instala un JDK con tu"
            warn "gestor de paquetes (ej: sudo pacman -S jdk-openjdk / sudo apt install openjdk-21-jdk)."
        fi
        exit 1
    fi
done
ok "OK"

# --- 2. Forge ---
if [[ -d "${MC_DIR}/versions/${FORGE_VERSION}" ]]; then
    step "Forge ${FORGE_VERSION} ya esta instalado, se omite este paso."
else
    step "Forge ${FORGE_VERSION} no encontrado. Descargando e instalando automaticamente..."
    installer_dir="$(mktemp -d)"
    installer="${installer_dir}/forge-installer.jar"
    curl -fSL -o "$installer" \
        "https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_VERSION}/forge-${FORGE_VERSION}-installer.jar"
    ok "Instalador descargado, ejecutando instalacion headless (puede tardar un minuto)..."
    mkdir -p "$MC_DIR"
    # El instalador de Forge se niega a instalar si el destino no tiene ya
    # un launcher_profiles.json (asume que el launcher oficial corrio ahi
    # al menos una vez). Si no existe, se crea uno minimo valido.
    if [[ ! -f "${MC_DIR}/launcher_profiles.json" ]]; then
        echo '{"profiles":{},"settings":{},"version":3}' > "${MC_DIR}/launcher_profiles.json"
    fi
    # El instalador de Forge necesita que le digamos la carpeta destino de
    # forma explicita -- sin eso, "--installClient" a secas instala en el
    # directorio actual (que puede no ser escribible) en vez de en
    # $MC_DIR, y falla.
    (cd "$installer_dir" && java -jar "forge-installer.jar" --installClient "$MC_DIR")
    rm -rf "$installer_dir"
    ok "Forge ${FORGE_VERSION} instalado."
fi

# --- 3. Descargar el pack ---
step "Buscando el ultimo release del pack..."
release_json="$(curl -fsSL "$REPO_API")"
asset_url="$(echo "$release_json" | python3 -c "import json,sys; d=json.load(sys.stdin); a=[x for x in d['assets'] if x['name'].endswith('.zip')]; print(a[0]['browser_download_url'] if a else '')")"
tag="$(echo "$release_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")"
if [[ -z "$asset_url" ]]; then
    warn "No se encontro ningun .zip en el ultimo release."
    exit 1
fi
ok "Version del pack: ${tag}"

zip_path="$(mktemp --suffix=.zip)"
step "Descargando pack..."
curl -fSL -o "$zip_path" "$asset_url"
ok "Descarga completa."

# --- 4. Extraer en la carpeta de juego propia ---
step "Instalando en ${GAME_DIR} ..."
mkdir -p "$GAME_DIR"
python3 -c "import zipfile; zipfile.ZipFile('${zip_path}').extractall('${GAME_DIR}')"
rm -f "$zip_path"
ok "Mods, resourcepacks, shaders y configuracion instalados."

# --- 5. Registrar el perfil en el launcher oficial ---
step "Registrando el perfil en el launcher..."
profiles_path="${MC_DIR}/launcher_profiles.json"
if [[ ! -f "$profiles_path" ]]; then
    warn "No se encontro launcher_profiles.json. Abri el launcher oficial al menos una vez y volve a correr este script."
    exit 1
fi
python3 - "$profiles_path" "$FORGE_VERSION" "$GAME_DIR" <<'PYEOF'
import json, sys
path, version, game_dir = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    data = json.load(f)
data.setdefault("profiles", {})["h3nx-arclight"] = {
    "name": "H3N-X (Arclight)",
    "type": "custom",
    "lastVersionId": version,
    "gameDir": game_dir,
    "javaArgs": "-Xmx6G -Xms2G",
}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
ok "Perfil 'H3N-X (Arclight)' creado/actualizado."

echo
echo -e "\033[32m========================================================\033[0m"
echo -e "\033[32m Listo! Abri el Minecraft Launcher, elegi el perfil\033[0m"
echo -e "\033[32m 'H3N-X (Arclight)' y dale Play.\033[0m"
echo
echo -e "\033[32m Direccion del servidor: ${SERVER_ADDRESS}\033[0m"
echo -e "\033[32m========================================================\033[0m"
