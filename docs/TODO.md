# Plan de Implementación - fac2csv

## Estado del Proyecto
Proyecto greenfield - Aplicación Flask para convertir facturas DIAN XML a CSV

---

## Tareas de Implementación

### Fase 1: Estructura Base del Proyecto
- [ ] Crear estructura de directorios del proyecto
- [ ] Crear `requirements.txt` con dependencias (Flask, lxml, pandas, werkzeug)
- [ ] Crear `.gitignore` para Python/Flask

### Fase 2: Backend - Parser XML
- [ ] Implementar `xml_parser.py`:
  - [ ] Definir constante `NAMESPACES` con URIs UBL 2.1
  - [ ] Función `parse_single_invoice(xml_path: str) -> dict`
  - [ ] Extracción de campos generales (numero_factura, prefijo, cufe, fechas)
  - [ ] Extracción de datos del cliente (nombre, NIT, dirección, etc.)
  - [ ] Extracción de datos del emisor
  - [ ] Extracción de valores monetarios (subtotal, IVA, impuestos, total)
  - [ ] Extracción de líneas de detalle (productos/servicios)
  - [ ] Manejo robusto de errores con try-except por campo
  - [ ] Definir excepción personalizada `ParseError`

### Fase 3: Backend - Generador CSV
- [ ] Implementar `csv_generator.py`:
  - [ ] Función `generate_summary_csv(invoices: list[dict], output_path: str)`
  - [ ] Función `generate_detail_csv(invoices: list[dict], output_path: str)`
  - [ ] Aplicar encoding UTF-8 con BOM
  - [ ] Formato de decimales con punto (2 decimales)
  - [ ] Headers en español
  - [ ] Definir excepción `CSVGenerationError`

### Fase 4: Backend - Utilidades
- [ ] Implementar `utils/validators.py`:
  - [ ] Validación de extensión `.xml`
  - [ ] Validación de tamaño (max 10MB)
  - [ ] Validación XML bien formado (lxml)
  - [ ] Validación de namespace UBL 2.1
  - [ ] Validación de tipo MIME
  - [ ] Definir excepción `ValidationError`

- [ ] Implementar `utils/file_manager.py`:
  - [ ] Función para sanitizar nombres de archivo
  - [ ] Función de limpieza automática (archivos >1 hora)
  - [ ] Creación de directorios `uploads/` y `outputs/`

### Fase 5: Backend - Flask App
- [ ] Implementar `app.py`:
  - [ ] Configuración básica de Flask
  - [ ] Configuración de logging
  - [ ] Ruta `GET /` - Página principal
  - [ ] Ruta `POST /upload` - Procesar XMLs subidos
  - [ ] Ruta `GET /results` - Mostrar resultados
  - [ ] Ruta `GET /download` - Descargar ZIP con CSVs
  - [ ] Manejo de errores con mensajes amigables
  - [ ] Integración con parser y generador CSV

### Fase 6: Frontend - Templates
- [ ] Crear `templates/base.html`:
  - [ ] Estructura HTML5 base
  - [ ] Integración de Bootstrap 5 (CDN)
  - [ ] Bloques para contenido y scripts
  - [ ] Navegación básica

- [ ] Crear `templates/index.html`:
  - [ ] Formulario de upload con drag-and-drop
  - [ ] Input file múltiple
  - [ ] Preview de archivos seleccionados
  - [ ] Indicador de progreso
  - [ ] Botón "Procesar" con estados

- [ ] Crear `templates/results.html`:
  - [ ] Tabla resumen de procesamiento
  - [ ] Lista de errores (si los hay)
  - [ ] Preview de primeros 10 registros de cada CSV
  - [ ] Botón de descarga ZIP
  - [ ] Link para procesar nuevos archivos

### Fase 7: Frontend - Assets
- [ ] Crear `static/css/style.css`:
  - [ ] Estilos personalizados para drag-and-drop
  - [ ] Estilos para preview de archivos
  - [ ] Estilos para tablas de resultados
  - [ ] Responsive design

- [ ] Crear `static/js/main.js`:
  - [ ] Validación de archivos .xml en cliente
  - [ ] Manejo de drag-and-drop
  - [ ] Preview de archivos seleccionados
  - [ ] Indicador de progreso durante upload
  - [ ] Deshabilitar botón hasta tener archivos válidos

### Fase 8: Testing y Validación
- [ ] Crear directorios `uploads/` y `outputs/`
- [ ] Probar con XML de ejemplo (`XML_BEC481550444.xml` si está disponible)
- [ ] Verificar generación correcta de ambos CSVs
- [ ] Verificar que Excel abre los CSVs sin problemas
- [ ] Probar con múltiples archivos simultáneos
- [ ] Probar manejo de errores (XML inválido, campos faltantes)
- [ ] Verificar limpieza automática de archivos temporales

### Fase 9: Documentación
- [ ] Crear `README.md` con:
  - [ ] Descripción del proyecto
  - [ ] Instrucciones de instalación
  - [ ] Comandos de ejecución
  - [ ] Estructura del proyecto
  - [ ] Ejemplos de uso

---

## Notas de Implementación

### Dependencias Principales (requirements.txt)
```
Flask>=2.3.0
lxml>=4.9.0
pandas>=2.0.0
Werkzeug>=2.3.0
```

### Orden Recomendado de Desarrollo
1. Parser XML (core logic) → Probar con XML de ejemplo
2. Generador CSV → Validar output
3. Utilidades (validators, file_manager)
4. Flask app y rutas
5. Templates y frontend
6. Testing integral

### Criterios de Éxito
- ✅ Procesa correctamente el XML de ejemplo
- ✅ Genera `facturas_resumen.csv` con todos los campos
- ✅ Genera `facturas_detalle.csv` con líneas expandidas
- ✅ Excel abre CSVs sin problemas de encoding
- ✅ Maneja hasta 50 archivos simultáneos
- ✅ UI intuitiva y responsive
- ✅ Errores reportados claramente

---

**Última actualización:** 2025-11-09
