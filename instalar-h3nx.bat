@echo off
setlocal enabledelayedexpansion

set "PACK_URL=https://raw.githubusercontent.com/h3n-x/minecraft-cliente-recomendado/main/H3NX-Cliente-Recomendado.zip"
set "DEST=%APPDATA%\.minecraft"
if not "%~1"=="" set "DEST=%~1"

echo === Instalador del cliente recomendado H3N-X ===
echo Destino: %DEST%
echo (si usas Prism Launcher/MultiMC, arrastra la carpeta .minecraft de tu
echo  instancia sobre este .bat, o pasala como argumento)
echo.

if not exist "%DEST%" (
    echo AVISO: no existe "%DEST%" todavia.
    echo Ya instalaste Fabric Loader para Minecraft 1.21.11 con el launcher oficial?
    choice /C SN /M "Crear la carpeta de todos modos"
    if errorlevel 2 (
        echo Cancelado. Instala Fabric primero: https://fabricmc.net/use/installer/
        pause
        exit /b 1
    )
    mkdir "%DEST%"
)

set "TMP=%TEMP%\h3nx_install_%RANDOM%"
mkdir "%TMP%"
mkdir "%TMP%\extracted"

echo Descargando el cliente recomendado (~73MB)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%PACK_URL%' -OutFile '%TMP%\pack.zip' -UseBasicParsing } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR al descargar el paquete. Revisa tu conexion a internet.
    rmdir /s /q "%TMP%"
    pause
    exit /b 1
)

echo Extrayendo...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Path '%TMP%\pack.zip' -DestinationPath '%TMP%\extracted' -Force } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR al extraer el paquete.
    rmdir /s /q "%TMP%"
    pause
    exit /b 1
)

echo Copiando mods, config, shaderpacks y resourcepacks a %DEST% ...
if not exist "%DEST%\mods" mkdir "%DEST%\mods"
if not exist "%DEST%\config" mkdir "%DEST%\config"
if not exist "%DEST%\shaderpacks" mkdir "%DEST%\shaderpacks"
if not exist "%DEST%\resourcepacks" mkdir "%DEST%\resourcepacks"

xcopy "%TMP%\extracted\mods\*" "%DEST%\mods\" /E /Y /I >nul
xcopy "%TMP%\extracted\config\*" "%DEST%\config\" /E /Y /I >nul
xcopy "%TMP%\extracted\shaderpacks\*" "%DEST%\shaderpacks\" /E /Y /I >nul
if exist "%TMP%\extracted\resourcepacks" xcopy "%TMP%\extracted\resourcepacks\*" "%DEST%\resourcepacks\" /E /Y /I >nul
if exist "%TMP%\extracted\journeymap" (
    if not exist "%DEST%\journeymap" mkdir "%DEST%\journeymap"
    xcopy "%TMP%\extracted\journeymap\*" "%DEST%\journeymap\" /E /Y /I >nul
)

set "HAS_FABRIC="
for /d %%D in ("%DEST%\versions\fabric-loader-*-1.21.11") do set "HAS_FABRIC=1"

if not defined HAS_FABRIC (
    echo.
    echo No se encontro Fabric Loader 1.21.11 -- instalandolo automaticamente...
    if not exist "%DEST%\launcher_profiles.json" (
        echo {"profiles":{},"settings":{},"version":3} > "%DEST%\launcher_profiles.json"
    )
    where java >nul 2>nul
    if errorlevel 1 (
        echo No se encontro "java" instalado -- no puedo instalar Fabric automaticamente.
    ) else (
        set "FABRIC_INSTALLER_URL="
        set "FABRIC_LOADER_VER="
        for /f "delims=" %%U in ('powershell -NoProfile -Command "(Invoke-RestMethod 'https://meta.fabricmc.net/v2/versions/installer')[0].url" 2^>nul') do set "FABRIC_INSTALLER_URL=%%U"
        for /f "delims=" %%L in ('powershell -NoProfile -Command "(Invoke-RestMethod 'https://meta.fabricmc.net/v2/versions/loader')[0].version" 2^>nul') do set "FABRIC_LOADER_VER=%%L"
        if defined FABRIC_INSTALLER_URL if defined FABRIC_LOADER_VER (
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '!FABRIC_INSTALLER_URL!' -OutFile '%TMP%\fabric-installer.jar' -UseBasicParsing" >nul 2>nul
            java -jar "%TMP%\fabric-installer.jar" client -mcversion 1.21.11 -loader !FABRIC_LOADER_VER! -dir "%DEST%" >nul 2>nul
            if errorlevel 1 (
                echo El instalador de Fabric fallo.
            ) else (
                echo Fabric Loader 1.21.11 instalado correctamente.
                set "HAS_FABRIC=1"
            )
        ) else (
            echo No pude consultar la version mas reciente de Fabric ^(¿sin internet?^).
        )
    )
)

rmdir /s /q "%TMP%"

echo.
if not defined HAS_FABRIC (
    echo === Copiado ok, pero FALTA UN PASO IMPORTANTE ===
    echo No se pudo instalar Fabric Loader 1.21.11 automaticamente.
    echo Los mods NO van a hacer nada hasta que lo instales vos:
    echo   1. Entra a https://fabricmc.net/use/installer/
    echo   2. Descarga el instalador, elegi Minecraft version 1.21.11
    echo   3. Instalalo, abri el launcher de Minecraft y elegi el nuevo perfil
    echo      "fabric-loader-1.21.11" antes de jugar.
) else (
    echo === Listo ===
    echo Fabric 1.21.11 esta instalado. Elegi el perfil "fabric-loader-1.21.11"
    echo en el launcher de Minecraft y jugá.
)
echo Adentro del juego: Mod Menu -^> FancyMenu, para asignar las imagenes
echo de menu (ya estan en config\fancymenu\assets\).
echo Al conectarte al server necesitas estar en la whitelist, y la primera
echo vez registrarte con: /register ^<contraseña^> ^<contraseña^>
echo.
pause
