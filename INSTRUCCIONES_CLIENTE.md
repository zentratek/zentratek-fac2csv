# Zentratek FAC2CSV - Guía del Usuario

**Versión:** 1.0.0
**Fecha:** 2025-11-12

---

## Descripción

Zentratek FAC2CSV es una aplicación web que convierte facturas electrónicas DIAN (formato XML) a archivos CSV para su análisis en Excel.

**Características principales:**

- Conversión de XML a CSV automática
- Interfaz web fácil de usar
- Procesamiento por lotes (hasta 50 archivos)
- Soporte para archivos ZIP
- Servicio de Windows con inicio automático
- Backups automáticos diarios

---

## Requisitos Previos

Antes de instalar, asegúrese de tener:

### 1. Python 3.10 o superior

**Descarga:** [https://www.python.org/downloads/](https://www.python.org/downloads/)

**Instalación importante:**
- Durante la instalación de Python, **MARQUE** la casilla **"Add Python to PATH"**
- Esta opción es crítica para que la aplicación funcione

### 2. Windows 10 u 11

- Permisos de Administrador
- Conexión a Internet (solo para instalación inicial)

### 3. Espacio en disco

- Mínimo: 500 MB
- Recomendado: 1 GB (para logs y backups)

---

## Instalación Rápida (3 Pasos)

### Paso 1: Extraer el archivo ZIP

Extraiga el contenido del ZIP descargado en una ubicación permanente, por ejemplo:
```
C:\Zentratek\fac2csv\
```

**IMPORTANTE:** No instale en carpetas temporales o en el Escritorio.

### Paso 2: Ejecutar el instalador

1. Busque el archivo `INSTALAR.bat`
2. **Clic derecho** sobre él
3. Seleccione **"Ejecutar como administrador"**
4. Siga las instrucciones en pantalla

El instalador realizará automáticamente:
- Verificación de Python
- Instalación de dependencias
- Generación de configuración segura
- Descarga e instalación de NSSM
- Creación del servicio de Windows
- Configuración del firewall
- Programación de backups

**Tiempo estimado:** 3-5 minutos

### Paso 3: Acceder a la aplicación

Una vez completada la instalación:

1. Abra su navegador web
2. Visite: [http://localhost:5000](http://localhost:5000)
3. Ya puede comenzar a convertir facturas

---

## Cómo Usar la Aplicación

### Conversión de Facturas

1. **Acceda a la aplicación:**
   - Abra su navegador
   - Visite: http://localhost:5000

2. **Cargue archivos:**
   - Haga clic en "Seleccionar archivos" o arrastre archivos
   - Puede cargar:
     - Archivos XML individuales
     - Archivos ZIP con múltiples XMLs
     - Hasta 50 archivos simultáneamente

3. **Procese:**
   - Haga clic en "Convertir"
   - Espere a que termine el procesamiento

4. **Descargue resultados:**
   - La aplicación generará 2 archivos CSV:
     - `facturas_resumen.csv` - Resumen de facturas
     - `facturas_detalle.csv` - Líneas de productos
   - Haga clic en "Descargar" para obtener un ZIP con ambos archivos

### Formatos de Salida

**facturas_resumen.csv:**
- Una fila por factura
- Información general, cliente, emisor, totales

**facturas_detalle.csv:**
- Una fila por línea de producto
- Incluye toda la info del resumen + detalles de productos

**Formato CSV:**
- Codificación: UTF-8 con BOM (compatible con Excel)
- Separador: Coma (`,`)
- Decimales: Punto (`.`)

---

## Gestión del Servicio

### Menú de Gestión

Para gestionar el servicio de Windows:

1. Busque el archivo `gestionar_servicio.bat`
2. Haga **doble clic** (no requiere permisos de administrador)
3. Use el menú interactivo:

```
[1] Iniciar servicio
[2] Detener servicio
[3] Reiniciar servicio
[4] Ver estado detallado
[5] Ver logs en tiempo real
[6] Ver log de errores
[7] Abrir aplicación en navegador
[8] Editar configuración (.env)
[9] Ejecutar backup manual
[0] Salir
```

### Estados del Servicio

- **RUNNING (Verde):** Servicio funcionando correctamente
- **STOPPED (Rojo):** Servicio detenido
- **NO INSTALADO (Rojo):** Servicio no configurado

### Inicio Automático

El servicio está configurado para **iniciar automáticamente** cuando se enciende Windows.

No necesita iniciar la aplicación manualmente.

---

## Backups Automáticos

### Programación

El sistema crea backups automáticos:

- **Frecuencia:** Diaria
- **Hora:** 2:00 AM
- **Ubicación:** `backups/backup_YYYY-MM-DD_HH-MM-SS/`

### Contenido del Backup

- Archivo de configuración (`.env`)
- Base de datos (`database.db`)
- Archivos de salida (últimos 7 días)
- Logs (últimos 30 días)

### Backup Manual

Para crear un backup inmediato:

1. Abra `gestionar_servicio.bat`
2. Seleccione opción **[9] Ejecutar backup manual**

O ejecute directamente:
```
backup.bat
```

### Retención

Los backups se conservan por **30 días** automáticamente.

---

## Configuración Avanzada

### Editar Configuración

Para cambiar configuraciones:

1. Abra `gestionar_servicio.bat`
2. Seleccione opción **[8] Editar configuración**
3. Modifique los valores deseados
4. Guarde y cierre el archivo
5. Reinicie el servicio (opción **[3]**)

### Opciones Configurables

**Servidor:**
- `PORT=5000` - Puerto de la aplicación
- `HOST=0.0.0.0` - Dirección del servidor
- `THREADS=4` - Hilos de procesamiento

**Archivos:**
- `MAX_CONTENT_LENGTH=10485760` - Tamaño máximo (10MB)
- `CLEANUP_AFTER_HOURS=1` - Limpieza automática (horas)

**Logging:**
- `LOG_LEVEL=INFO` - Nivel de detalle (DEBUG, INFO, WARNING, ERROR)

**Seguridad:**
- `SECRET_KEY` - Clave de seguridad (generada automáticamente)

---

## Limitaciones

### Límites de Archivos

- **Tamaño máximo por archivo:** 10 MB
- **Archivos simultáneos:** 50
- **Formatos aceptados:** .xml, .zip

### Requisitos de XML

- Formato: UBL 2.1
- Estándar: Factura electrónica DIAN Colombia
- Codificación: UTF-8

### Capacidad del Sistema

- Procesamiento: ~10 facturas por segundo
- Almacenamiento: Logs y outputs se limpian automáticamente

---

## Desinstalación

Para desinstalar la aplicación:

### Opción 1: Desinstalador Completo

1. Busque el archivo `DESINSTALAR.bat`
2. **Clic derecho** → **"Ejecutar como administrador"**
3. Siga las instrucciones en pantalla
4. Elija qué componentes eliminar:
   - Servicio de Windows
   - Firewall
   - Tarea de backup
   - NSSM
   - Archivos de la aplicación
   - Dependencias Python

### Opción 2: Desinstalación Parcial

Use el desinstalador pero conserve:
- NSSM (si tiene otros servicios)
- Dependencias Python (si tiene otras apps Python)
- Archivos de la aplicación (para reinstalar después)

### Backup Automático

El desinstalador crea un backup automático en su Escritorio antes de eliminar archivos.

---

## Problemas Comunes

### La aplicación no abre en el navegador

**Solución:**
1. Verifique que el servicio esté corriendo:
   ```
   gestionar_servicio.bat → [4] Ver estado
   ```
2. Verifique el puerto en uso:
   - Abra el archivo `.env`
   - Busque la línea `PORT=5000`
   - Intente con ese puerto: http://localhost:PUERTO

### Error: "Puerto ya en uso"

**Solución:**
1. Cambie el puerto:
   ```
   gestionar_servicio.bat → [8] Editar configuración
   ```
2. Cambie `PORT=5000` por otro puerto (ej: `PORT=8080`)
3. Guarde y reinicie el servicio

### El servicio no inicia

**Solución:**
1. Verifique los logs de error:
   ```
   gestionar_servicio.bat → [6] Ver log de errores
   ```
2. Causas comunes:
   - Python no instalado correctamente
   - Dependencias faltantes
   - Puerto ocupado
   - Permisos insuficientes

3. Reinstale si es necesario:
   ```
   DESINSTALAR.bat (conservar archivos)
   INSTALAR.bat
   ```

### Error: "Python no encontrado"

**Solución:**
1. Verifique instalación de Python:
   - Abra CMD
   - Ejecute: `python --version`
   - Debe mostrar: Python 3.10.x o superior

2. Si no funciona:
   - Reinstale Python
   - **MARQUE** "Add Python to PATH"
   - Reinicie el sistema
   - Ejecute `INSTALAR.bat` nuevamente

### Los archivos CSV no abren bien en Excel

**Solución:**
1. Los CSV están en UTF-8 con BOM (compatible con Excel)
2. Si tiene problemas:
   - Abra Excel
   - Vaya a: Datos → Obtener datos → Desde archivo → Desde texto/CSV
   - Seleccione el archivo CSV
   - Codificación: UTF-8
   - Delimitador: Coma

### Backup no funciona

**Solución:**
1. Verifique que `backup.bat` existe
2. Ejecute manualmente:
   ```
   gestionar_servicio.bat → [9] Backup manual
   ```
3. Verifique permisos en la carpeta `backups/`

---

## Soporte Técnico

### Logs y Diagnóstico

Si tiene problemas, revise estos archivos:

**Logs de instalación:**
```
logs/instalacion_cliente.log
```

**Logs del servicio:**
```
logs/service_output.log
logs/service_error.log
```

**Logs de la aplicación:**
```
logs/app.log
```

### Información para Soporte

Al reportar un problema, incluya:

1. **Versión de la aplicación:** 1.0.0
2. **Versión de Python:** `python --version`
3. **Versión de Windows:** Windows 10 / 11
4. **Estado del servicio:** Copie salida de opción [4] del menú
5. **Logs de error:** Copie contenido de `logs/service_error.log`
6. **Descripción del problema:** ¿Qué estaba intentando hacer?

### Comandos Útiles

**Verificar servicio:**
```cmd
sc query ZentratekFAC2CSV
```

**Verificar puerto:**
```cmd
netstat -an | findstr ":5000"
```

**Verificar Python:**
```cmd
python --version
python -m pip list
```

---

## Preguntas Frecuentes

### ¿Necesito Internet para usar la aplicación?

No. Una vez instalada, la aplicación funciona completamente offline.

Internet solo se necesita durante la instalación inicial para descargar NSSM.

### ¿Puedo acceder desde otra computadora?

Sí, pero requiere configuración adicional:

1. Edite `.env`
2. Cambie `HOST=0.0.0.0` (permite acceso externo)
3. Configure el firewall de Windows
4. Acceda usando: http://IP_DEL_SERVIDOR:5000

**Seguridad:** Solo haga esto en redes confiables.

### ¿Los datos se guardan en línea?

No. Todo el procesamiento es local. Los archivos nunca salen de su computadora.

### ¿Cuántas facturas puedo procesar?

- **Por lote:** Hasta 50 archivos simultáneamente
- **Diarias:** Sin límite
- **Tamaño:** Cada archivo hasta 10 MB

### ¿Se actualiza automáticamente?

No. Las actualizaciones son manuales:

1. Descargue la nueva versión
2. Ejecute `DESINSTALAR.bat` (conserve archivos)
3. Extraiga la nueva versión
4. Ejecute `INSTALAR.bat`

### ¿Puedo mover la aplicación a otra carpeta?

Sí, pero debe:

1. Detener el servicio
2. Ejecutar `DESINSTALAR.bat`
3. Mover la carpeta completa
4. Ejecutar `INSTALAR.bat` desde la nueva ubicación

---

## Licencia y Créditos

**Zentratek FAC2CSV**
Versión 1.0.0

© 2025 Zentratek
Todos los derechos reservados

**Tecnologías utilizadas:**
- Python 3.10+
- Flask (framework web)
- lxml (procesamiento XML)
- pandas (generación CSV)
- Waitress (servidor WSGI)
- NSSM (gestor de servicios)

---

## Changelog

### Versión 1.0.0 (2025-11-12)

**Funcionalidades:**
- ✅ Conversión XML a CSV
- ✅ Soporte para archivos ZIP
- ✅ Interfaz web amigable
- ✅ Servicio de Windows con inicio automático
- ✅ Instalador automático de un clic
- ✅ Menú de gestión interactivo
- ✅ Backups automáticos diarios
- ✅ Configuración mediante archivo .env
- ✅ Logs detallados
- ✅ Desinstalador con opciones

**Primera versión estable para producción.**

---

**¡Gracias por usar Zentratek FAC2CSV!**

Para más información, consulte la documentación técnica en:
- `README.md` - Información general del proyecto
- `INSTALL_WINDOWS.md` - Guía técnica detallada
- `WINDOWS_QUICKSTART.md` - Referencia rápida
