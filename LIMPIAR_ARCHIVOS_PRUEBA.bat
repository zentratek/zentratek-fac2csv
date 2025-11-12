@echo off
REM ============================================================
REM Zentratek FAC2CSV - LIMPIEZA DE ARCHIVOS DE PRUEBA
REM ============================================================
REM Version: 1.0.0
REM Fecha: 2025-11-12
REM
REM Este script elimina archivos de prueba y desarrollo
REM antes de entregar el proyecto al cliente final.
REM
REM Conserva:
REM - INSTALAR.bat
REM - DESINSTALAR.bat
REM - gestionar_servicio.bat
REM - backup.bat
REM - Archivos Python (.py)
REM - Templates y static
REM - Documentacion oficial
REM
REM Elimina:
REM - Scripts de prueba antiguos
REM - Logs de instalacion antiguos
REM - Entorno virtual (opcional)
REM - Archivos temporales
REM ============================================================

setlocal enabledelayedexpansion

REM ====================
REM Initialize
REM ====================
color 0E
cls
echo.
echo ============================================================
echo     ZENTRATEK FAC2CSV - LIMPIEZA DE ARCHIVOS DE PRUEBA
echo ============================================================
echo.
echo Version: 1.0.0
echo.
echo Este script eliminara archivos de prueba y desarrollo:
echo.
echo Archivos a eliminar:
echo  - test_server.bat
echo  - iniciar_servidor.bat
echo  - instalar_windows.bat
echo  - reparar_servicio.bat
echo  - configurar_servicio_wrapper.bat
echo  - start_service.bat
echo  - instalar_servicio_simple.bat
echo  - instalar_tarea_programada.bat
echo  - instalar_inicio_automatico.bat
echo  - desinstalar_windows.bat
echo  - start_hidden.vbs
echo  - logs/instalacion.log (antiguo)
echo.
echo Archivos a conservar:
echo  - INSTALAR.bat (PRINCIPAL)
echo  - DESINSTALAR.bat
echo  - gestionar_servicio.bat
echo  - backup.bat
echo  - run_server.py
echo  - Todos los archivos .py de la aplicacion
echo  - Templates, static, utils
echo  - Documentacion (.md)
echo.
echo ============================================================
echo.

choice /C SN /M "Desea continuar con la limpieza?"
if %errorlevel% equ 2 (
    echo.
    echo Limpieza cancelada
    pause
    exit /b 0
)

REM ====================
REM Clean Old Scripts
REM ====================
echo.
echo ============================================================
echo Eliminando scripts de prueba antiguos...
echo ============================================================
echo.

set "FILES_DELETED=0"
set "FILES_NOT_FOUND=0"

REM List of test files to delete
set FILES[0]=test_server.bat
set FILES[1]=iniciar_servidor.bat
set FILES[2]=instalar_windows.bat
set FILES[3]=reparar_servicio.bat
set FILES[4]=configurar_servicio_wrapper.bat
set FILES[5]=start_service.bat
set FILES[6]=instalar_servicio_simple.bat
set FILES[7]=instalar_tarea_programada.bat
set FILES[8]=instalar_inicio_automatico.bat
set FILES[9]=desinstalar_windows.bat
set FILES[10]=start_hidden.vbs

REM Count files
set "FILE_COUNT=11"

REM Delete each file
for /L %%i in (0,1,10) do (
    if exist "%~dp0!FILES[%%i]!" (
        echo [DEL] !FILES[%%i]!
        del /F /Q "%~dp0!FILES[%%i]!" >nul 2>&1
        if !errorlevel! equ 0 (
            set /a FILES_DELETED+=1
        )
    ) else (
        echo [SKIP] !FILES[%%i]! - No encontrado
        set /a FILES_NOT_FOUND+=1
    )
)

echo.
echo Archivos eliminados: %FILES_DELETED%
echo Archivos no encontrados: %FILES_NOT_FOUND%

REM ====================
REM Clean Old Logs
REM ====================
echo.
echo ============================================================
echo Limpiando logs antiguos...
echo ============================================================
echo.

if exist "%~dp0logs\instalacion.log" (
    echo [DEL] logs\instalacion.log
    del /F /Q "%~dp0logs\instalacion.log" >nul 2>&1
) else (
    echo [SKIP] logs\instalacion.log - No encontrado
)

REM ====================
REM Clean Virtual Environment (Optional)
REM ====================
echo.
echo ============================================================
echo Entorno virtual (venv)
echo ============================================================
echo.

if exist "%~dp0venv" (
    echo Se encontro un entorno virtual en: %~dp0venv
    echo.
    echo NOTA: El instalador principal usa Python global (no venv)
    echo Por lo tanto, este directorio no es necesario
    echo.
    choice /C SN /M "Desea eliminar el directorio venv?"
    if !errorlevel! equ 1 (
        echo.
        echo Eliminando venv...
        rd /S /Q "%~dp0venv" >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Directorio venv eliminado
        ) else (
            echo [ERROR] No se pudo eliminar venv
        )
    ) else (
        echo [SKIP] venv conservado
    )
) else (
    echo [INFO] No se encontro directorio venv
)

REM ====================
REM Clean Temp Files
REM ====================
echo.
echo ============================================================
echo Limpiando archivos temporales...
echo ============================================================
echo.

REM Clean Python cache
if exist "%~dp0__pycache__" (
    echo [DEL] __pycache__
    rd /S /Q "%~dp0__pycache__" >nul 2>&1
)

REM Clean .pyc files
for /r "%~dp0" %%f in (*.pyc) do (
    echo [DEL] %%~nxf
    del /F /Q "%%f" >nul 2>&1
)

REM Clean pytest cache
if exist "%~dp0.pytest_cache" (
    echo [DEL] .pytest_cache
    rd /S /Q "%~dp0.pytest_cache" >nul 2>&1
)

echo.
echo [OK] Archivos temporales limpiados

REM ====================
REM Verify Important Files
REM ====================
echo.
echo ============================================================
echo Verificando archivos importantes...
echo ============================================================
echo.

set "MISSING_FILES=0"

REM Check essential files
if exist "%~dp0INSTALAR.bat" (
    echo [OK] INSTALAR.bat
) else (
    echo [ERROR] INSTALAR.bat - FALTANTE
    set /a MISSING_FILES+=1
)

if exist "%~dp0DESINSTALAR.bat" (
    echo [OK] DESINSTALAR.bat
) else (
    echo [ERROR] DESINSTALAR.bat - FALTANTE
    set /a MISSING_FILES+=1
)

if exist "%~dp0gestionar_servicio.bat" (
    echo [OK] gestionar_servicio.bat
) else (
    echo [ERROR] gestionar_servicio.bat - FALTANTE
    set /a MISSING_FILES+=1
)

if exist "%~dp0run_server.py" (
    echo [OK] run_server.py
) else (
    echo [ERROR] run_server.py - FALTANTE
    set /a MISSING_FILES+=1
)

if exist "%~dp0.env.example" (
    echo [OK] .env.example
) else (
    echo [ERROR] .env.example - FALTANTE
    set /a MISSING_FILES+=1
)

if exist "%~dp0app.py" (
    echo [OK] app.py
) else (
    echo [ERROR] app.py - FALTANTE
    set /a MISSING_FILES+=1
)

if exist "%~dp0requirements.txt" (
    echo [OK] requirements.txt
) else (
    echo [ERROR] requirements.txt - FALTANTE
    set /a MISSING_FILES+=1
)

if %MISSING_FILES% gtr 0 (
    color 0C
    echo.
    echo [ADVERTENCIA] Faltan %MISSING_FILES% archivos importantes!
) else (
    echo.
    echo [OK] Todos los archivos importantes estan presentes
)

REM ====================
REM Summary
REM ====================
echo.
echo ============================================================
echo     LIMPIEZA COMPLETADA
echo ============================================================
echo.

if %MISSING_FILES% gtr 0 (
    color 0E
    echo [ADVERTENCIA] Se completo la limpieza pero faltan archivos
) else (
    color 0A
    echo [OK] Limpieza completada exitosamente
)

echo.
echo Archivos eliminados: %FILES_DELETED%
echo.
echo El proyecto esta listo para entrega al cliente
echo.
echo Proximos pasos:
echo 1. Revisar que todos los archivos importantes existan
echo 2. Probar INSTALAR.bat en un sistema limpio
echo 3. Comprimir el directorio en ZIP
echo 4. Enviar al cliente con INSTRUCCIONES_CLIENTE.md
echo.
echo ============================================================
echo.
pause

endlocal
exit /b 0
