@echo off
REM ============================================================
REM Zentratek FAC2CSV - Service Management Script
REM ============================================================
REM Version: 1.0.0
REM Fecha: 2025-11-12
REM
REM Script de gestion interactiva del servicio Windows
REM Proporciona menu con opciones para:
REM - Iniciar/Detener/Reiniciar servicio
REM - Ver estado y logs
REM - Abrir aplicacion en navegador
REM - Editar configuracion
REM - Ejecutar backup manual
REM ============================================================

setlocal enabledelayedexpansion

REM ====================
REM Configuracion
REM ====================
set "SERVICE_NAME=ZentratekFAC2CSV"
set "NSSM_DIR=C:\nssm"
set "NSSM_EXE=%NSSM_DIR%\win64\nssm.exe"
set "APP_DIR=%~dp0"

REM ====================
REM Main Menu Loop
REM ====================
:MENU
cls
color 0B
echo.
echo ============================================================
echo     ZENTRATEK FAC2CSV - GESTION DE SERVICIO
echo ============================================================
echo.

REM Get service status
set "SERVICE_STATUS=DESCONOCIDO"
set "SERVICE_COLOR=0E"

sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('sc query "%SERVICE_NAME%" ^| find "STATE"') do (
        set "SERVICE_STATUS=%%a"
    )

    if "!SERVICE_STATUS!"=="RUNNING" (
        set "SERVICE_COLOR=0A"
    ) else if "!SERVICE_STATUS!"=="STOPPED" (
        set "SERVICE_COLOR=0C"
    ) else (
        set "SERVICE_COLOR=0E"
    )
) else (
    set "SERVICE_STATUS=NO INSTALADO"
    set "SERVICE_COLOR=0C"
)

color !SERVICE_COLOR!

echo Estado del servicio: !SERVICE_STATUS!
echo.

color 0B

echo OPCIONES DISPONIBLES:
echo.
echo  [1] Iniciar servicio
echo  [2] Detener servicio
echo  [3] Reiniciar servicio
echo  [4] Ver estado detallado
echo  [5] Ver logs en tiempo real
echo  [6] Ver log de errores
echo  [7] Abrir aplicacion en navegador
echo  [8] Editar configuracion (.env)
echo  [9] Ejecutar backup manual
echo  [0] Salir
echo.
echo ============================================================
echo.

set /p "CHOICE=Seleccione una opcion [0-9]: "

if "%CHOICE%"=="1" goto :START_SERVICE
if "%CHOICE%"=="2" goto :STOP_SERVICE
if "%CHOICE%"=="3" goto :RESTART_SERVICE
if "%CHOICE%"=="4" goto :STATUS_SERVICE
if "%CHOICE%"=="5" goto :VIEW_LOGS
if "%CHOICE%"=="6" goto :VIEW_ERROR_LOGS
if "%CHOICE%"=="7" goto :OPEN_BROWSER
if "%CHOICE%"=="8" goto :EDIT_CONFIG
if "%CHOICE%"=="9" goto :RUN_BACKUP
if "%CHOICE%"=="0" goto :EXIT

echo.
echo [ERROR] Opcion invalida
timeout /t 2 /nobreak >nul
goto :MENU

REM ====================
REM Start Service
REM ====================
:START_SERVICE
cls
echo.
echo ============================================================
echo INICIANDO SERVICIO
echo ============================================================
echo.

sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] El servicio no esta instalado
    echo.
    echo Por favor, ejecute INSTALAR.bat primero
    echo.
    pause
    goto :MENU
)

REM Check if already running
sc query "%SERVICE_NAME%" | find "RUNNING" >nul
if %errorlevel% equ 0 (
    color 0E
    echo [INFO] El servicio ya esta en ejecucion
    echo.
    pause
    goto :MENU
)

echo Iniciando servicio...

if exist "%NSSM_EXE%" (
    "%NSSM_EXE%" start "%SERVICE_NAME%"
) else (
    net start "%SERVICE_NAME%"
)

if %errorlevel% equ 0 (
    color 0A
    echo.
    echo [OK] Servicio iniciado correctamente
    echo.
    echo Esperando a que el servicio este listo...
    timeout /t 5 /nobreak >nul

    REM Check if actually running
    sc query "%SERVICE_NAME%" | find "RUNNING" >nul
    if %errorlevel% equ 0 (
        echo [OK] El servicio esta corriendo
        echo.
        choice /C SN /M "Desea abrir la aplicacion en el navegador?"
        if !errorlevel! equ 1 (
            REM Get port from .env
            set "PORT=5000"
            if exist "%APP_DIR%.env" (
                for /f "tokens=2 delims==" %%a in ('findstr /i "^PORT=" "%APP_DIR%.env"') do set "PORT=%%a"
            )
            start http://localhost:!PORT!
        )
    ) else (
        color 0C
        echo [ERROR] El servicio no esta corriendo
        echo Revise los logs de error
    )
) else (
    color 0C
    echo.
    echo [ERROR] No se pudo iniciar el servicio
    echo.
    echo Posibles causas:
    echo - Puerto ya en uso
    echo - Error en configuracion
    echo - Dependencias faltantes
    echo.
    echo Revise los logs para mas detalles (opcion 6)
)

echo.
pause
goto :MENU

REM ====================
REM Stop Service
REM ====================
:STOP_SERVICE
cls
echo.
echo ============================================================
echo DETENIENDO SERVICIO
echo ============================================================
echo.

sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] El servicio no esta instalado
    echo.
    pause
    goto :MENU
)

REM Check if already stopped
sc query "%SERVICE_NAME%" | find "STOPPED" >nul
if %errorlevel% equ 0 (
    color 0E
    echo [INFO] El servicio ya esta detenido
    echo.
    pause
    goto :MENU
)

echo Deteniendo servicio...

if exist "%NSSM_EXE%" (
    "%NSSM_EXE%" stop "%SERVICE_NAME%"
) else (
    net stop "%SERVICE_NAME%"
)

if %errorlevel% equ 0 (
    color 0A
    echo.
    echo [OK] Servicio detenido correctamente
) else (
    color 0C
    echo.
    echo [ERROR] No se pudo detener el servicio
)

echo.
pause
goto :MENU

REM ====================
REM Restart Service
REM ====================
:RESTART_SERVICE
cls
echo.
echo ============================================================
echo REINICIANDO SERVICIO
echo ============================================================
echo.

sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] El servicio no esta instalado
    echo.
    pause
    goto :MENU
)

echo Deteniendo servicio...

if exist "%NSSM_EXE%" (
    "%NSSM_EXE%" stop "%SERVICE_NAME%"
) else (
    net stop "%SERVICE_NAME%"
)

timeout /t 3 /nobreak >nul

echo Iniciando servicio...

if exist "%NSSM_EXE%" (
    "%NSSM_EXE%" start "%SERVICE_NAME%"
) else (
    net start "%SERVICE_NAME%"
)

if %errorlevel% equ 0 (
    color 0A
    echo.
    echo [OK] Servicio reiniciado correctamente
    echo.
    echo Esperando a que el servicio este listo...
    timeout /t 5 /nobreak >nul
) else (
    color 0C
    echo.
    echo [ERROR] No se pudo reiniciar el servicio
)

echo.
pause
goto :MENU

REM ====================
REM Status Service
REM ====================
:STATUS_SERVICE
cls
echo.
echo ============================================================
echo ESTADO DETALLADO DEL SERVICIO
echo ============================================================
echo.

sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] El servicio no esta instalado
    echo.
    pause
    goto :MENU
)

REM Show service details
echo Informacion del servicio:
echo ------------------------
sc query "%SERVICE_NAME%"
sc qc "%SERVICE_NAME%"

echo.
echo ------------------------
echo Puertos en escucha:
echo ------------------------
netstat -an | findstr ":5000"

echo.
echo ------------------------
echo Procesos Python:
echo ------------------------
tasklist /FI "IMAGENAME eq python.exe" 2>nul

echo.
pause
goto :MENU

REM ====================
REM View Logs
REM ====================
:VIEW_LOGS
cls
echo.
echo ============================================================
echo LOGS EN TIEMPO REAL
echo ============================================================
echo.
echo Mostrando ultimas lineas del log...
echo Presione Ctrl+C para volver al menu
echo.
echo ============================================================
echo.

if exist "%APP_DIR%logs\service_output.log" (
    powershell -Command "Get-Content '%APP_DIR%logs\service_output.log' -Tail 50 -Wait"
) else if exist "%APP_DIR%logs\app.log" (
    powershell -Command "Get-Content '%APP_DIR%logs\app.log' -Tail 50 -Wait"
) else (
    color 0E
    echo [INFO] No se encontraron archivos de log
    echo.
    pause
)

goto :MENU

REM ====================
REM View Error Logs
REM ====================
:VIEW_ERROR_LOGS
cls
echo.
echo ============================================================
echo LOG DE ERRORES
echo ============================================================
echo.

if exist "%APP_DIR%logs\service_error.log" (
    echo Contenido del log de errores:
    echo.
    type "%APP_DIR%logs\service_error.log"
) else (
    color 0A
    echo [OK] No hay errores registrados
)

echo.
echo ============================================================
echo.
pause
goto :MENU

REM ====================
REM Open Browser
REM ====================
:OPEN_BROWSER
cls
echo.
echo ============================================================
echo ABRIR APLICACION EN NAVEGADOR
echo ============================================================
echo.

REM Get port from .env
set "PORT=5000"
if exist "%APP_DIR%.env" (
    for /f "tokens=2 delims==" %%a in ('findstr /i "^PORT=" "%APP_DIR%.env"') do set "PORT=%%a"
)

echo Abriendo http://localhost:!PORT! en el navegador...
echo.

start http://localhost:!PORT!

timeout /t 2 /nobreak >nul
goto :MENU

REM ====================
REM Edit Configuration
REM ====================
:EDIT_CONFIG
cls
echo.
echo ============================================================
echo EDITAR CONFIGURACION
echo ============================================================
echo.

if not exist "%APP_DIR%.env" (
    color 0C
    echo [ERROR] Archivo .env no encontrado
    echo.
    pause
    goto :MENU
)

echo Abriendo archivo .env en el Bloc de notas...
echo.
echo IMPORTANTE: Despues de editar, reinicie el servicio
echo para que los cambios tengan efecto
echo.

notepad "%APP_DIR%.env"

echo.
choice /C SN /M "Desea reiniciar el servicio ahora?"
if !errorlevel! equ 1 (
    goto :RESTART_SERVICE
)

goto :MENU

REM ====================
REM Run Backup
REM ====================
:RUN_BACKUP
cls
echo.
echo ============================================================
echo EJECUTAR BACKUP MANUAL
echo ============================================================
echo.

if not exist "%APP_DIR%backup.bat" (
    color 0C
    echo [ERROR] Script backup.bat no encontrado
    echo.
    pause
    goto :MENU
)

echo Ejecutando backup...
echo.

call "%APP_DIR%backup.bat"

echo.
echo ============================================================
echo.
pause
goto :MENU

REM ====================
REM Exit
REM ====================
:EXIT
cls
echo.
echo ============================================================
echo     Saliendo...
echo ============================================================
echo.
echo Gracias por usar Zentratek FAC2CSV
echo.

endlocal
exit /b 0
