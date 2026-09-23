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

echo Descargando el cliente recomendado (~52MB)...
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

rmdir /s /q "%TMP%"

echo.
echo === Listo ===
echo 1. Abri el launcher de Minecraft, elegi el perfil de Fabric Loader 1.21.11.
echo 2. Adentro del juego: Mod Menu -^> FancyMenu, para asignar las imagenes
echo    de menu (ya estan en config\fancymenu\assets\).
echo 3. Al conectarte al server necesitas estar en la whitelist, y la primera
echo    vez registrarte con: /register ^<contraseña^> ^<contraseña^>
echo.
pause
