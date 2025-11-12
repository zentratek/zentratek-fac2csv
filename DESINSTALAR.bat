@echo off
REM ============================================================
REM Zentratek FAC2CSV - DESINSTALADOR COMPLETO
REM ============================================================
REM Version: 1.0.0
REM Fecha: 2025-11-12
REM
REM Este desinstalador elimina:
REM - Servicio de Windows
REM - Regla de firewall
REM - Tarea programada de backup
REM - Procesos Python en ejecucion
REM - Archivos de la aplicacion (opcional)
REM - Dependencias Python (opcional)
REM
REM IMPORTANTE: Ejecutar como Administrador
REM ============================================================

setlocal enabledelayedexpansion

REM ====================
REM Configuracion
REM ====================
set "SERVICE_NAME=ZentratekFAC2CSV"
set "NSSM_DIR=C:\nssm"
set "NSSM_EXE=%NSSM_DIR%\win64\nssm.exe"

REM Log file
set "LOG_DIR=%~dp0logs"
set "LOG_FILE=%LOG_DIR%\desinstalacion.log"

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
    echo 1. Clic derecho en DESINSTALAR.bat
    echo 2. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

REM ====================
REM Initialize
REM ====================
color 0E
cls
echo.
echo ============================================================
echo     ZENTRATEK FAC2CSV - DESINSTALADOR
echo ============================================================
echo.
echo Version: 1.0.0
echo.
echo ADVERTENCIA: Este proceso eliminara:
echo.
echo  [1/8] Servicio de Windows
echo  [2/8] Regla de firewall
echo  [3/8] Tarea programada de backup
echo  [4/8] Procesos Python en ejecucion
echo  [5/8] NSSM (opcional)
echo  [6/8] Archivos de la aplicacion (opcional)
echo  [7/8] Dependencias Python (opcional)
echo  [8/8] Crear log de desinstalacion
echo.
echo ============================================================
echo.

choice /C SN /M "Esta seguro que desea continuar con la desinstalacion?"
if !errorlevel! equ 2 (
    echo.
    echo Desinstalacion cancelada por el usuario
    pause
    exit /b 0
)

REM Create log directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Start logging
echo ============================================================ > "%LOG_FILE%"
echo Zentratek FAC2CSV - Log de Desinstalacion >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo Fecha: %date% %time% >> "%LOG_FILE%"
echo Usuario: %USERNAME% >> "%LOG_FILE%"
echo Directorio: %~dp0 >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM ====================
REM Step 1: Remove Windows Service
REM ====================
echo.
echo ============================================================
echo [1/8] Eliminando servicio de Windows
echo ============================================================
echo.

echo [INFO] Eliminando servicio... >> "%LOG_FILE%"

REM Check if service exists
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Servicio encontrado. Deteniendolo...

    REM Stop with NSSM if available
    if exist "%NSSM_EXE%" (
        "%NSSM_EXE%" stop "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
        timeout /t 3 /nobreak >nul
    ) else (
        REM Fallback to sc
        sc stop "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
        timeout /t 3 /nobreak >nul
    )

    echo Eliminando servicio...

    REM Remove with NSSM if available
    if exist "%NSSM_EXE%" (
        "%NSSM_EXE%" remove "%SERVICE_NAME%" confirm >> "%LOG_FILE%" 2>&1
    ) else (
        REM Fallback to sc
        sc delete "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
    )

    if %errorlevel% equ 0 (
        echo [OK] Servicio eliminado correctamente
        echo [OK] Servicio eliminado >> "%LOG_FILE%"
    ) else (
        echo [ERROR] No se pudo eliminar el servicio
        echo [ERROR] Fallo al eliminar servicio >> "%LOG_FILE%"
    )
) else (
    echo [INFO] Servicio no encontrado
    echo [INFO] Servicio no encontrado >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 2: Remove Firewall Rule
REM ====================
echo.
echo ============================================================
echo [2/8] Eliminando regla de firewall
echo ============================================================
echo.

echo [INFO] Eliminando regla firewall... >> "%LOG_FILE%"

netsh advfirewall firewall show rule name="%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    netsh advfirewall firewall delete rule name="%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Regla de firewall eliminada
        echo [OK] Regla firewall eliminada >> "%LOG_FILE%"
    ) else (
        echo [ERROR] No se pudo eliminar la regla de firewall
        echo [ERROR] Fallo al eliminar regla firewall >> "%LOG_FILE%"
    )
) else (
    echo [INFO] Regla de firewall no encontrada
    echo [INFO] Regla firewall no encontrada >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 3: Remove Scheduled Task
REM ====================
echo.
echo ============================================================
echo [3/8] Eliminando tarea programada de backup
echo ============================================================
echo.

echo [INFO] Eliminando tarea programada... >> "%LOG_FILE%"

schtasks /query /tn "%SERVICE_NAME%_Backup" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "%SERVICE_NAME%_Backup" /f >> "%LOG_FILE%" 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Tarea programada eliminada
        echo [OK] Tarea programada eliminada >> "%LOG_FILE%"
    ) else (
        echo [ERROR] No se pudo eliminar la tarea programada
        echo [ERROR] Fallo al eliminar tarea programada >> "%LOG_FILE%"
    )
) else (
    echo [INFO] Tarea programada no encontrada
    echo [INFO] Tarea programada no encontrada >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 4: Stop Python Processes
REM ====================
echo.
echo ============================================================
echo [4/8] Deteniendo procesos Python
echo ============================================================
echo.

echo [INFO] Deteniendo procesos... >> "%LOG_FILE%"

REM Check for running Python processes related to the app
tasklist /FI "IMAGENAME eq python.exe" 2>nul | find /I "python.exe" >nul
if %errorlevel% equ 0 (
    echo Procesos Python encontrados. Deteniendolos...

    REM Try to stop by port first
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5000"') do (
        taskkill /F /PID %%a >> "%LOG_FILE%" 2>&1
    )

    REM Stop pythonw.exe processes
    taskkill /F /IM pythonw.exe >> "%LOG_FILE%" 2>&1

    echo [OK] Procesos detenidos
    echo [OK] Procesos Python detenidos >> "%LOG_FILE%"
) else (
    echo [INFO] No hay procesos Python en ejecucion
    echo [INFO] No hay procesos Python >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 5: Remove NSSM (Optional)
REM ====================
echo.
echo ============================================================
echo [5/8] Eliminar NSSM? (opcional)
echo ============================================================
echo.
echo NSSM esta instalado en: %NSSM_DIR%
echo.
echo NOTA: Otros servicios podrian estar usando NSSM
echo.

choice /C SN /M "Desea eliminar NSSM?"
if !errorlevel! equ 1 (
    if exist "%NSSM_DIR%" (
        echo Eliminando NSSM...
        rd /S /Q "%NSSM_DIR%" >> "%LOG_FILE%" 2>&1
        if %errorlevel% equ 0 (
            echo [OK] NSSM eliminado
            echo [OK] NSSM eliminado >> "%LOG_FILE%"
        ) else (
            echo [ERROR] No se pudo eliminar NSSM
            echo [ERROR] Fallo al eliminar NSSM >> "%LOG_FILE%"
        )
    ) else (
        echo [INFO] NSSM no encontrado
        echo [INFO] NSSM no encontrado >> "%LOG_FILE%"
    )
) else (
    echo [INFO] NSSM conservado
    echo [INFO] NSSM conservado >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 6: Remove Application Files (Optional)
REM ====================
echo.
echo ============================================================
echo [6/8] Eliminar archivos de la aplicacion? (opcional)
echo ============================================================
echo.
echo ADVERTENCIA: Esta accion NO se puede deshacer
echo.
echo Se eliminaran todos los archivos de la aplicacion:
echo - Codigo fuente (.py)
echo - Configuracion (.env)
echo - Templates y archivos estaticos
echo - Logs
echo - Outputs y uploads
echo.
echo Se creara un backup automatico en el Escritorio
echo.

choice /C SN /M "Desea eliminar TODOS los archivos de la aplicacion?"
if !errorlevel! equ 1 (
    REM Double confirmation
    echo.
    echo ============================================================
    echo CONFIRMACION FINAL
    echo ============================================================
    echo.
    echo Esta accion eliminara PERMANENTEMENTE todos los archivos
    echo de la aplicacion en: %~dp0
    echo.
    echo Para confirmar, escriba: ELIMINAR
    echo Para cancelar, presione Enter
    echo.
    set /p "CONFIRM=Confirmacion: "

    if /I "!CONFIRM!"=="ELIMINAR" (
        REM Create backup first
        echo.
        echo Creando backup en el Escritorio...
        set "BACKUP_DIR=%USERPROFILE%\Desktop\zentratek_backup_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
        set "BACKUP_DIR=!BACKUP_DIR: =0!"

        mkdir "!BACKUP_DIR!" >> "%LOG_FILE%" 2>&1

        REM Copy important files
        xcopy "%~dp0*.py" "!BACKUP_DIR%\" /Y >> "%LOG_FILE%" 2>&1
        xcopy "%~dp0*.bat" "!BACKUP_DIR%\" /Y >> "%LOG_FILE%" 2>&1
        xcopy "%~dp0.env" "!BACKUP_DIR%\" /Y >> "%LOG_FILE%" 2>&1
        xcopy "%~dp0requirements.txt" "!BACKUP_DIR%\" /Y >> "%LOG_FILE%" 2>&1

        if exist "%~dp0logs" xcopy "%~dp0logs" "!BACKUP_DIR%\logs\" /E /I /Y >> "%LOG_FILE%" 2>&1
        if exist "%~dp0backups" xcopy "%~dp0backups" "!BACKUP_DIR%\backups\" /E /I /Y >> "%LOG_FILE%" 2>&1

        echo [OK] Backup creado en: !BACKUP_DIR!
        echo [OK] Backup creado en Escritorio >> "%LOG_FILE%"

        REM Note: Cannot delete current directory while script is running
        REM Create a cleanup script that will run after this script exits
        echo @echo off > "%TEMP%\cleanup_zentratek.bat"
        echo timeout /t 3 /nobreak ^>nul >> "%TEMP%\cleanup_zentratek.bat"
        echo rd /S /Q "%~dp0" ^>nul 2^>^&1 >> "%TEMP%\cleanup_zentratek.bat"
        echo del "%%~f0" >> "%TEMP%\cleanup_zentratek.bat"

        echo.
        echo [OK] Archivos seran eliminados al cerrar esta ventana
        echo [OK] Eliminacion programada >> "%LOG_FILE%"

        REM Schedule cleanup
        start /min "" "%TEMP%\cleanup_zentratek.bat"

        echo.
        echo Presione cualquier tecla para cerrar...
        pause >nul
        exit /b 0
    ) else (
        echo.
        echo [INFO] Eliminacion cancelada
        echo [INFO] Eliminacion de archivos cancelada >> "%LOG_FILE%"
    )
) else (
    echo [INFO] Archivos conservados
    echo [INFO] Archivos de aplicacion conservados >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 7: Uninstall Python Dependencies (Optional)
REM ====================
echo.
echo ============================================================
echo [7/8] Desinstalar dependencias Python? (opcional)
echo ============================================================
echo.
echo ADVERTENCIA: Las dependencias estan instaladas globalmente
echo Otras aplicaciones Python podrian estar usandolas
echo.
echo Dependencias:
echo - Flask, lxml, pandas, Werkzeug
echo - gunicorn, waitress, python-dotenv
echo.

choice /C SN /M "Desea desinstalar las dependencias Python?"
if !errorlevel! equ 1 (
    echo.
    echo Desinstalando dependencias...

    if exist "%~dp0requirements.txt" (
        python -m pip uninstall -r "%~dp0requirements.txt" -y >> "%LOG_FILE%" 2>&1
        if %errorlevel% equ 0 (
            echo [OK] Dependencias desinstaladas
            echo [OK] Dependencias desinstaladas >> "%LOG_FILE%"
        ) else (
            echo [ERROR] No se pudo desinstalar algunas dependencias
            echo [ERROR] Fallo al desinstalar dependencias >> "%LOG_FILE%"
        )
    ) else (
        echo [WARNING] requirements.txt no encontrado
        echo [WARNING] requirements.txt no encontrado >> "%LOG_FILE%"
    )
) else (
    echo [INFO] Dependencias conservadas
    echo [INFO] Dependencias Python conservadas >> "%LOG_FILE%"
)

timeout /t 2 /nobreak >nul

REM ====================
REM Step 8: Finalize
REM ====================
echo.
echo ============================================================
echo [8/8] Finalizando desinstalacion
echo ============================================================
echo.

echo. >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo DESINSTALACION COMPLETADA >> "%LOG_FILE%"
echo Fecha fin: %date% %time% >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

color 0A
echo.
echo ============================================================
echo     DESINSTALACION COMPLETADA
echo ============================================================
echo.
echo Log de desinstalacion guardado en:
echo %LOG_FILE%
echo.
echo Elementos eliminados:
echo [OK] Servicio de Windows
echo [OK] Regla de firewall
echo [OK] Tarea programada de backup
echo [OK] Procesos Python detenidos
echo.
echo Gracias por usar Zentratek FAC2CSV
echo ============================================================
echo.
echo Presione cualquier tecla para cerrar...
pause >nul

endlocal
exit /b 0
