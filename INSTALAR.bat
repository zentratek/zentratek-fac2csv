@echo off
REM ============================================================
REM Zentratek FAC2CSV - INSTALADOR PARA CLIENTE FINAL
REM ============================================================
REM Version: 1.0.0
REM Fecha: 2025-11-12
REM
REM Este instalador configura automaticamente:
REM - Instala dependencias Python (globalmente, NO venv)
REM - Genera SECRET_KEY segura
REM - Descarga e instala NSSM
REM - Crea servicio Windows con inicio automatico
REM - Configura firewall
REM - Programa backups automaticos
REM
REM IMPORTANTE: Ejecutar como Administrador
REM ============================================================

setlocal enabledelayedexpansion

REM ====================
REM Configuracion
REM ====================
set "SERVICE_NAME=ZentratekFAC2CSV"
set "SERVICE_DISPLAY_NAME=Zentratek FAC2CSV Service"
set "SERVICE_DESCRIPTION=Servicio de conversion de facturas DIAN XML a CSV"
set "DEFAULT_PORT=5000"
set "NSSM_VERSION=2.24"
set "NSSM_DIR=C:\nssm"
set "NSSM_EXE=%NSSM_DIR%\win64\nssm.exe"
set "NSSM_URL=https://nssm.cc/release/nssm-%NSSM_VERSION%.zip"

REM Log file
set "LOG_DIR=%~dp0logs"
set "LOG_FILE=%LOG_DIR%\instalacion_cliente.log"

REM ====================
REM Check Administrator
REM ====================
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ========================================================
    echo ERROR: Este script requiere permisos de Administrador
    echo ========================================================
    echo.
    echo Por favor:
    echo 1. Clic derecho en INSTALAR.bat
    echo 2. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

REM ====================
REM Initialize
REM ====================
color 0B
cls
echo.
echo ============================================================
echo     ZENTRATEK FAC2CSV - INSTALADOR AUTOMATICO
echo ============================================================
echo.
echo Version: 1.0.0
echo Fecha: 2025-11-12
echo.
echo Este instalador configurara automaticamente:
echo.
echo  [1] Verificar Python 3.10+
echo  [2] Instalar dependencias
echo  [3] Generar configuracion segura
echo  [4] Descargar e instalar NSSM
echo  [5] Crear servicio de Windows
echo  [6] Configurar firewall
echo  [7] Programar backups automaticos
echo.
echo Tiempo estimado: 3-5 minutos
echo.
echo ============================================================
echo.
pause

REM Create log directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Start logging
echo ============================================================ > "%LOG_FILE%"
echo Zentratek FAC2CSV - Log de Instalacion >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo Fecha: %date% %time% >> "%LOG_FILE%"
echo Usuario: %USERNAME% >> "%LOG_FILE%"
echo Directorio: %~dp0 >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM ====================
REM Step 1: Check Python
REM ====================
cls
echo.
echo ============================================================
echo [1/7] Verificando Python 3.10+
echo ============================================================
echo.

echo [INFO] Verificando Python... >> "%LOG_FILE%"

python --version >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Python no esta instalado >> "%LOG_FILE%"
    echo.
    echo ERROR: Python no esta instalado
    echo.
    echo Por favor:
    echo 1. Descargue Python 3.10 o superior desde python.org
    echo 2. Durante la instalacion, marque "Add Python to PATH"
    echo 3. Reinicie este instalador
    echo.
    pause
    exit /b 1
)

REM Get Python version
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYTHON_VERSION=%%v
echo Python version: %PYTHON_VERSION%
echo [OK] Python version: %PYTHON_VERSION% >> "%LOG_FILE%"

REM Get Python path
for /f "tokens=*" %%p in ('where python 2^>nul') do (
    echo %%p | findstr /V "WindowsApps" >nul
    if !errorlevel! equ 0 (
        set "PYTHON_PATH=%%p"
        goto :python_found
    )
)
REM If no real Python found, use whatever is available
for /f "delims=" %%p in ('where python 2^>nul') do (
    set "PYTHON_PATH=%%p"
    goto :python_found
)

:python_found
echo Python path: %PYTHON_PATH%
echo [OK] Python path: %PYTHON_PATH% >> "%LOG_FILE%"

REM Warn if using WindowsApps Python
echo %PYTHON_PATH% | findstr "WindowsApps" >nul
if !errorlevel! equ 0 (
    color 0E
    echo.
    echo [ADVERTENCIA] Se detecto Python de Microsoft Store
    echo Esto puede causar problemas al ejecutar como servicio
    echo Se recomienda instalar Python desde python.org
    echo.
    echo [WARNING] Python de WindowsApps detectado >> "%LOG_FILE%"
    timeout /t 3
)


REM Check Python version >= 3.10
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set PYTHON_MAJOR=%%a
    set PYTHON_MINOR=%%b
)

if %PYTHON_MAJOR% lss 3 (
    color 0C
    echo.
    echo ERROR: Python version muy antigua: %PYTHON_VERSION%
    echo Se requiere Python 3.10 o superior
    echo.
    echo [ERROR] Python version muy antigua: %PYTHON_VERSION% >> "%LOG_FILE%"
    pause
    exit /b 1
)

if %PYTHON_MAJOR% equ 3 if %PYTHON_MINOR% lss 10 (
    color 0C
    echo.
    echo ERROR: Python version muy antigua: %PYTHON_VERSION%
    echo Se requiere Python 3.10 o superior
    echo.
    echo [ERROR] Python version muy antigua: %PYTHON_VERSION% >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo.
echo [OK] Python %PYTHON_VERSION% detectado correctamente
echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Step 2: Install Dependencies
REM ====================
cls
echo.
echo ============================================================
echo [2/7] Instalando dependencias Python
echo ============================================================
echo.
echo IMPORTANTE: Las dependencias se instalaran GLOBALMENTE
echo (no en entorno virtual) para que el servicio funcione.
echo.

echo [INFO] Instalando dependencias... >> "%LOG_FILE%"

REM Upgrade pip first
echo Actualizando pip...
python -m pip install --upgrade pip >> "%LOG_FILE%" 2>&1

REM Install requirements
echo Instalando paquetes desde requirements.txt...
echo.
python -m pip install -r "%~dp0requirements.txt" >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ERROR: Fallo la instalacion de dependencias
    echo Revise el log: %LOG_FILE%
    echo.
    echo [ERROR] Fallo instalacion de dependencias >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo.
echo [OK] Dependencias instaladas correctamente
echo [OK] Dependencias instaladas >> "%LOG_FILE%"
echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Step 3: Configure Application
REM ====================
cls
echo.
echo ============================================================
echo [3/7] Configurando aplicacion
echo ============================================================
echo.

echo [INFO] Configurando aplicacion... >> "%LOG_FILE%"

REM Check for existing .env
if exist "%~dp0.env" (
    echo Se encontro archivo .env existente
    echo.
    choice /C SN /M "Desea conservar la configuracion actual? (S=Si, N=Crear nueva)"
    if !errorlevel! equ 1 (
        echo [INFO] Se conserva .env existente >> "%LOG_FILE%"
        echo.
        echo [OK] Se conservo la configuracion existente
        goto :skip_env_creation
    )
    REM Backup existing .env
    echo Creando backup de .env actual...
    copy "%~dp0.env" "%~dp0.env.backup.%date:~-4%%date:~3,2%%date:~0,2%" >nul
    echo [INFO] Backup de .env creado >> "%LOG_FILE%"
)

REM Create .env from template
if not exist "%~dp0.env.example" (
    color 0C
    echo.
    echo ERROR: No se encontro .env.example
    echo.
    echo [ERROR] No se encontro .env.example >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo Creando archivo .env desde plantilla...
copy "%~dp0.env.example" "%~dp0.env" >nul

REM Generate SECRET_KEY using Python
echo Generando SECRET_KEY segura...
python -c "import secrets, base64; print(base64.b64encode(secrets.token_bytes(32)).decode())" > "%TEMP%\secret_key.txt" 2>nul

if exist "%TEMP%\secret_key.txt" (
    set /p GENERATED_KEY=<"%TEMP%\secret_key.txt"
    del "%TEMP%\secret_key.txt"

    REM Replace SECRET_KEY in .env
    powershell -Command "(Get-Content '%~dp0.env') -replace 'SECRET_KEY=.*', 'SECRET_KEY=!GENERATED_KEY!' | Set-Content '%~dp0.env'" >> "%LOG_FILE%" 2>&1

    echo [OK] SECRET_KEY generada y configurada >> "%LOG_FILE%"
    echo [OK] SECRET_KEY generada correctamente
) else (
    echo [WARNING] No se pudo generar SECRET_KEY automaticamente >> "%LOG_FILE%"
    echo [AVISO] No se pudo generar SECRET_KEY automaticamente
    echo [AVISO] Por favor, edite manualmente el archivo .env
)

:skip_env_creation

REM Ask for port
echo.
echo Puerto predeterminado: %DEFAULT_PORT%
choice /C SN /M "Desea usar el puerto predeterminado %DEFAULT_PORT%?"
if !errorlevel! equ 2 (
    set /p "USER_PORT=Ingrese el puerto deseado: "

    REM Update PORT in .env
    powershell -Command "(Get-Content '%~dp0.env') -replace 'PORT=.*', 'PORT=!USER_PORT!' | Set-Content '%~dp0.env'" >> "%LOG_FILE%" 2>&1

    echo [INFO] Puerto configurado: !USER_PORT! >> "%LOG_FILE%"
    echo [OK] Puerto configurado: !USER_PORT!
) else (
    set "USER_PORT=%DEFAULT_PORT%"
    echo [INFO] Puerto predeterminado: %DEFAULT_PORT% >> "%LOG_FILE%"
    echo [OK] Puerto predeterminado: %DEFAULT_PORT%
)

echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Step 4: Install NSSM
REM ====================
cls
echo.
echo ============================================================
echo [4/7] Instalando NSSM (Non-Sucking Service Manager)
echo ============================================================
echo.

echo [INFO] Instalando NSSM... >> "%LOG_FILE%"

if exist "%NSSM_EXE%" (
    echo NSSM ya esta instalado en: %NSSM_EXE%
    echo [INFO] NSSM ya instalado >> "%LOG_FILE%"
) else (
    echo Descargando NSSM %NSSM_VERSION%...

    REM Create NSSM directory
    if not exist "%NSSM_DIR%" mkdir "%NSSM_DIR%"

    REM Download NSSM using PowerShell
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NSSM_URL%' -OutFile '%TEMP%\nssm.zip'}" >> "%LOG_FILE%" 2>&1

    if %errorlevel% neq 0 (
        color 0C
        echo.
        echo ERROR: No se pudo descargar NSSM
        echo Por favor, descargue manualmente desde: https://nssm.cc
        echo.
        echo [ERROR] Fallo descarga de NSSM >> "%LOG_FILE%"
        pause
        exit /b 1
    )

    echo Extrayendo NSSM...
    powershell -Command "Expand-Archive -Path '%TEMP%\nssm.zip' -DestinationPath '%TEMP%\nssm_extract' -Force" >> "%LOG_FILE%" 2>&1

    REM Copy NSSM files
    xcopy "%TEMP%\nssm_extract\nssm-%NSSM_VERSION%\*" "%NSSM_DIR%\" /E /I /Y >nul

    REM Cleanup
    del "%TEMP%\nssm.zip" >nul 2>&1
    rd /S /Q "%TEMP%\nssm_extract" >nul 2>&1

    echo [OK] NSSM instalado en: %NSSM_DIR% >> "%LOG_FILE%"
    echo [OK] NSSM instalado correctamente
)

echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Step 5: Create Windows Service
REM ====================
cls
echo.
echo ============================================================
echo [5/7] Creando servicio de Windows
echo ============================================================
echo.

echo [INFO] Creando servicio Windows... >> "%LOG_FILE%"

REM Check if service already exists
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Servicio existente detectado. Deteniendolo...
    "%NSSM_EXE%" stop "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
    timeout /t 3 /nobreak >nul

    echo Eliminando servicio anterior...
    "%NSSM_EXE%" remove "%SERVICE_NAME%" confirm >> "%LOG_FILE%" 2>&1
    echo [INFO] Servicio anterior eliminado >> "%LOG_FILE%"
)

REM Install service
echo Instalando servicio...
"%NSSM_EXE%" install "%SERVICE_NAME%" "%PYTHON_PATH%" "%~dp0run_server.py" >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ERROR: No se pudo crear el servicio
    echo Revise el log: %LOG_FILE%
    echo.
    echo [ERROR] Fallo creacion de servicio >> "%LOG_FILE%"
    pause
    exit /b 1
)

REM Configure service
echo Configurando servicio...

REM Set display name and description
"%NSSM_EXE%" set "%SERVICE_NAME%" DisplayName "%SERVICE_DISPLAY_NAME%" >> "%LOG_FILE%" 2>&1
"%NSSM_EXE%" set "%SERVICE_NAME%" Description "%SERVICE_DESCRIPTION%" >> "%LOG_FILE%" 2>&1

REM Set working directory (without extra quotes)
set "APP_DIR=%~dp0"
set "APP_DIR=%APP_DIR:~0,-1%"
"%NSSM_EXE%" set "%SERVICE_NAME%" AppDirectory "%APP_DIR%" >> "%LOG_FILE%" 2>&1

REM Set startup type to automatic
"%NSSM_EXE%" set "%SERVICE_NAME%" Start SERVICE_AUTO_START >> "%LOG_FILE%" 2>&1

REM Configure logging
"%NSSM_EXE%" set "%SERVICE_NAME%" AppStdout "%APP_DIR%\logs\service_output.log" >> "%LOG_FILE%" 2>&1
"%NSSM_EXE%" set "%SERVICE_NAME%" AppStderr "%APP_DIR%\logs\service_error.log" >> "%LOG_FILE%" 2>&1

REM Set log rotation
"%NSSM_EXE%" set "%SERVICE_NAME%" AppRotateFiles 1 >> "%LOG_FILE%" 2>&1
"%NSSM_EXE%" set "%SERVICE_NAME%" AppRotateOnline 1 >> "%LOG_FILE%" 2>&1
"%NSSM_EXE%" set "%SERVICE_NAME%" AppRotateBytes 10485760 >> "%LOG_FILE%" 2>&1

REM Start service
echo Iniciando servicio...
"%NSSM_EXE%" start "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    color 0E
    echo.
    echo ADVERTENCIA: El servicio se creo pero no se pudo iniciar
    echo Puede iniciarlo manualmente con: gestionar_servicio.bat
    echo.
    echo [WARNING] Servicio creado pero no iniciado >> "%LOG_FILE%"
) else (
    echo [OK] Servicio creado e iniciado >> "%LOG_FILE%"
    echo [OK] Servicio creado e iniciado correctamente
)

echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Step 6: Configure Firewall
REM ====================
cls
echo.
echo ============================================================
echo [6/7] Configurando firewall
echo ============================================================
echo.

echo [INFO] Configurando firewall... >> "%LOG_FILE%"

REM Remove existing rule if present
netsh advfirewall firewall show rule name="%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Eliminando regla de firewall existente...
    netsh advfirewall firewall delete rule name="%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
)

REM Add new firewall rule
echo Creando regla de firewall para puerto %USER_PORT%...
netsh advfirewall firewall add rule name="%SERVICE_NAME%" dir=in action=allow protocol=TCP localport=%USER_PORT% >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    color 0E
    echo.
    echo ADVERTENCIA: No se pudo configurar el firewall
    echo Puede que necesite hacerlo manualmente
    echo.
    echo [WARNING] Fallo configuracion firewall >> "%LOG_FILE%"
) else (
    echo [OK] Firewall configurado >> "%LOG_FILE%"
    echo [OK] Firewall configurado correctamente
)

echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Step 7: Schedule Backup
REM ====================
cls
echo.
echo ============================================================
echo [7/7] Programando backups automaticos
echo ============================================================
echo.

echo [INFO] Programando backup automatico... >> "%LOG_FILE%"

REM Check if backup.bat exists
if not exist "%~dp0backup.bat" (
    echo [WARNING] backup.bat no encontrado, saltando... >> "%LOG_FILE%"
    echo [AVISO] backup.bat no encontrado, saltando programacion
    goto :skip_backup
)

REM Delete existing task if present
schtasks /query /tn "%SERVICE_NAME%_Backup" >nul 2>&1
if %errorlevel% equ 0 (
    echo Eliminando tarea programada existente...
    schtasks /delete /tn "%SERVICE_NAME%_Backup" /f >> "%LOG_FILE%" 2>&1
)

REM Create scheduled task for daily backup at 2:00 AM
echo Creando tarea programada (diaria a las 2:00 AM)...
schtasks /create /tn "%SERVICE_NAME%_Backup" /tr "\"%~dp0backup.bat\"" /sc daily /st 02:00 /ru SYSTEM /rl HIGHEST /f >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    color 0E
    echo.
    echo ADVERTENCIA: No se pudo programar el backup automatico
    echo Puede ejecutar backup.bat manualmente
    echo.
    echo [WARNING] Fallo programacion de backup >> "%LOG_FILE%"
) else (
    echo [OK] Backup programado >> "%LOG_FILE%"
    echo [OK] Backup automatico programado correctamente
)

:skip_backup

echo.
timeout /t 2 /nobreak >nul

REM ====================
REM Installation Complete
REM ====================
cls
color 0A
echo.
echo ============================================================
echo     INSTALACION COMPLETADA EXITOSAMENTE
echo ============================================================
echo.
echo [OK] Python: %PYTHON_VERSION%
echo [OK] Dependencias instaladas globalmente
echo [OK] Configuracion: .env creado
echo [OK] NSSM: Instalado en %NSSM_DIR%
echo [OK] Servicio: %SERVICE_NAME%
echo [OK] Firewall: Puerto %USER_PORT%
echo [OK] Backup: Programado diariamente (2:00 AM)
echo.
echo ============================================================
echo.
echo La aplicacion ya esta funcionando!
echo.
echo Para acceder:
echo   http://localhost:%USER_PORT%
echo.
echo Para gestionar el servicio:
echo   Ejecute: gestionar_servicio.bat
echo.
echo Log de instalacion:
echo   %LOG_FILE%
echo.
echo ============================================================
echo.

echo. >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo INSTALACION COMPLETADA >> "%LOG_FILE%"
echo Fecha fin: %date% %time% >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

REM Wait for service to be fully started
echo Esperando a que el servicio inicie completamente...
timeout /t 5 /nobreak >nul

REM Check if service is running
sc query "%SERVICE_NAME%" | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo.
    echo [OK] El servicio esta corriendo correctamente
    echo.
    choice /C SN /M "Desea abrir la aplicacion en el navegador?"
    if !errorlevel! equ 1 (
        start http://localhost:%USER_PORT%
    )
) else (
    color 0E
    echo.
    echo [AVISO] El servicio no esta corriendo
    echo Por favor, inicie el servicio con: gestionar_servicio.bat
)

echo.
echo Presione cualquier tecla para salir...
pause >nul

endlocal
exit /b 0
