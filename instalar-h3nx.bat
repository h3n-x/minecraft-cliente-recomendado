@echo off
setlocal enabledelayedexpansion

set "FORGE_VERSION=1.20.1-47.4.10"
set "MC_DIR=%APPDATA%\.minecraft"
set "GAME_DIR=%APPDATA%\.minecraft-arclight-h3nx"
set "REPO_API=https://api.github.com/repos/h3n-x/minecraft-cliente-recomendado/releases/latest"
set "SERVER_ADDRESS=laurel-wants.tun.ply.gg"

echo === Instalador del cliente recomendado H3N-X (Arclight + Forge 1.20.1) ===
echo.
echo Este pack NO es compatible con el cliente viejo de Fabric -- el server
echo ahora corre Arclight (Forge). Se instala en una carpeta propia
echo ^(%GAME_DIR%^) para no mezclarse con tus otras instalaciones.
echo.

where java >nul 2>nul
if errorlevel 1 (
    echo No se encontro "java" instalado.
    echo Instala el launcher oficial de Minecraft ^(https://www.minecraft.net/download^)
    echo y abrilo al menos una vez -- trae su propio Java.
    pause
    exit /b 1
)

if not exist "%MC_DIR%\versions\%FORGE_VERSION%" (
    echo Forge %FORGE_VERSION% no esta instalado -- instalandolo automaticamente...
    if not exist "%MC_DIR%" mkdir "%MC_DIR%"
    if not exist "%MC_DIR%\launcher_profiles.json" (
        echo {"profiles":{},"settings":{},"version":3} > "%MC_DIR%\launcher_profiles.json"
    )
    set "TMP=%TEMP%\h3nx_install_%RANDOM%"
    mkdir "!TMP!"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri 'https://maven.minecraftforge.net/net/minecraftforge/forge/%FORGE_VERSION%/forge-%FORGE_VERSION%-installer.jar' -OutFile '!TMP!\forge-installer.jar' -UseBasicParsing } catch { exit 1 }"
    if errorlevel 1 (
        echo ERROR al descargar el instalador de Forge. Revisa tu conexion a internet.
        pause
        exit /b 1
    )
    echo Ejecutando instalacion headless de Forge ^(puede tardar un minuto^)...
    pushd "!TMP!"
    java -jar "forge-installer.jar" --installClient "%MC_DIR%"
    set "FORGE_RC=!errorlevel!"
    popd
    if !FORGE_RC! neq 0 (
        echo El instalador de Forge fallo. Instalalo manualmente desde:
        echo https://files.minecraftforge.net/net/minecraftforge/forge/index_1.20.1.html
        pause
        exit /b 1
    )
    rmdir /s /q "!TMP!"
    echo Forge %FORGE_VERSION% instalado correctamente.
) else (
    echo Forge %FORGE_VERSION% ya esta instalado, se omite este paso.
)
echo.

echo Buscando el ultimo release del pack...
set "ASSET_URL="
set "PACK_VERSION="
for /f "delims=" %%U in ('powershell -NoProfile -Command "$r = Invoke-RestMethod '%REPO_API%'; ($r.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1).browser_download_url" 2^>nul') do set "ASSET_URL=%%U"
for /f "delims=" %%V in ('powershell -NoProfile -Command "(Invoke-RestMethod '%REPO_API%').tag_name" 2^>nul') do set "PACK_VERSION=%%V"
if not defined ASSET_URL (
    echo No se pudo encontrar el ultimo release del pack. Revisa tu conexion.
    pause
    exit /b 1
)
echo Version del pack: %PACK_VERSION%

set "TMP2=%TEMP%\h3nx_pack_%RANDOM%"
mkdir "%TMP2%"
echo Descargando el pack ^(puede pesar varios cientos de MB^)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%ASSET_URL%' -OutFile '%TMP2%\pack.zip' -UseBasicParsing } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR al descargar el paquete.
    pause
    exit /b 1
)

echo Instalando en %GAME_DIR% ...
if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%TMP2%\pack.zip' -DestinationPath '%GAME_DIR%' -Force"
rmdir /s /q "%TMP2%"
echo Mods, resourcepacks, shaders y configuracion instalados.
echo.

echo Registrando el perfil en el launcher...
if not exist "%MC_DIR%\launcher_profiles.json" (
    echo No se encontro launcher_profiles.json. Abri el launcher oficial al
    echo menos una vez y volve a correr este instalador.
    pause
    exit /b 1
)
rem El "^" de continuacion de linea de CMD no es confiable dentro de un
rem bloque -Command entre comillas (rompe el parseo con pipes/parentesis
rem anidados). En vez de eso se manda el script ya en base64 UTF-16LE via
rem -EncodedCommand, que no depende de ningun escapeo de CMD. El script
rem en claro (antes de codificar) es:
rem   $McDir = Join-Path $env:APPDATA '.minecraft'
rem   $GameDir = Join-Path $env:APPDATA '.minecraft-arclight-h3nx'
rem   $Version = '1.20.1-47.4.10'
rem   $profilesPath = Join-Path $McDir 'launcher_profiles.json'
rem   $p = Get-Content $profilesPath -Raw ^| ConvertFrom-Json
rem   $prof = [PSCustomObject]@{ name = 'H3N-X (Arclight)'; type = 'custom'; lastVersionId = $Version; gameDir = $GameDir; javaArgs = '-Xmx6G -Xms2G' }
rem   $p.profiles ^| Add-Member -NotePropertyName 'h3nx-arclight' -NotePropertyValue $prof -Force
rem   $p ^| ConvertTo-Json -Depth 20 ^| Set-Content -Path $profilesPath -Encoding UTF8
powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABNAGMARABpAHIAIAA9ACAASgBvAGkAbgAtAFAAYQB0AGgAIAAkAGUAbgB2ADoAQQBQAFAARABBAFQAQQAgACcALgBtAGkAbgBlAGMAcgBhAGYAdAAnAAoAJABHAGEAbQBlAEQAaQByACAAPQAgAEoAbwBpAG4ALQBQAGEAdABoACAAJABlAG4AdgA6AEEAUABQAEQAQQBUAEEAIAAnAC4AbQBpAG4AZQBjAHIAYQBmAHQALQBhAHIAYwBsAGkAZwBoAHQALQBoADMAbgB4ACcACgAkAFYAZQByAHMAaQBvAG4AIAA9ACAAJwAxAC4AMgAwAC4AMQAtADQANwAuADQALgAxADAAJwAKACQAcAByAG8AZgBpAGwAZQBzAFAAYQB0AGgAIAA9ACAASgBvAGkAbgAtAFAAYQB0AGgAIAAkAE0AYwBEAGkAcgAgACcAbABhAHUAbgBjAGgAZQByAF8AcAByAG8AZgBpAGwAZQBzAC4AagBzAG8AbgAnAAoAJABwACAAPQAgAEcAZQB0AC0AQwBvAG4AdABlAG4AdAAgACQAcAByAG8AZgBpAGwAZQBzAFAAYQB0AGgAIAAtAFIAYQB3ACAAfAAgAEMAbwBuAHYAZQByAHQARgByAG8AbQAtAEoAcwBvAG4ACgAkAHAAcgBvAGYAIAA9ACAAWwBQAFMAQwB1AHMAdABvAG0ATwBiAGoAZQBjAHQAXQBAAHsAIABuAGEAbQBlACAAPQAgACcASAAzAE4ALQBYACAAKABBAHIAYwBsAGkAZwBoAHQAKQAnADsAIAB0AHkAcABlACAAPQAgACcAYwB1AHMAdABvAG0AJwA7ACAAbABhAHMAdABWAGUAcgBzAGkAbwBuAEkAZAAgAD0AIAAkAFYAZQByAHMAaQBvAG4AOwAgAGcAYQBtAGUARABpAHIAIAA9ACAAJABHAGEAbQBlAEQAaQByADsAIABqAGEAdgBhAEEAcgBnAHMAIAA9ACAAJwAtAFgAbQB4ADYARwAgAC0AWABtAHMAMgBHACcAIAB9AAoAJABwAC4AcAByAG8AZgBpAGwAZQBzACAAfAAgAEEAZABkAC0ATQBlAG0AYgBlAHIAIAAtAE4AbwB0AGUAUAByAG8AcABlAHIAdAB5AE4AYQBtAGUAIAAnAGgAMwBuAHgALQBhAHIAYwBsAGkAZwBoAHQAJwAgAC0ATgBvAHQAZQBQAHIAbwBwAGUAcgB0AHkAVgBhAGwAdQBlACAAJABwAHIAbwBmACAALQBGAG8AcgBjAGUACgAkAHAAIAB8ACAAQwBvAG4AdgBlAHIAdABUAG8ALQBKAHMAbwBuACAALQBEAGUAcAB0AGgAIAAyADAAIAB8ACAAUwBlAHQALQBDAG8AbgB0AGUAbgB0ACAALQBQAGEAdABoACAAJABwAHIAbwBmAGkAbABlAHMAUABhAHQAaAAgAC0ARQBuAGMAbwBkAGkAbgBnACAAVQBUAEYAOAAKAA==
if errorlevel 1 (
    echo No se pudo registrar el perfil automaticamente. Podes crearlo a
    echo mano en el launcher: version "%FORGE_VERSION%", Game Directory
    echo "%GAME_DIR%".
)

echo.
echo === Listo ===
echo Abri el Minecraft Launcher, elegi el perfil "H3N-X (Arclight)" y dale Play.
echo.
echo Direccion del servidor: %SERVER_ADDRESS%
echo.
echo Adentro del juego: la primera vez que entres tenes 2 minutos para
echo escribir en el chat:  /register ^<contraseña^> ^<contraseña^>
echo Las siguientes veces:  /login ^<contraseña^>
echo.
pause
