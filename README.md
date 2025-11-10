# Convertidor XML Facturas DIAN a CSV

Aplicación web Flask para convertir facturas electrónicas XML (formato DIAN Colombia - UBL 2.1) a archivos CSV.

## Características

- ✅ Conversión de facturas DIAN XML (UBL 2.1) a formato CSV
- ✅ Procesamiento por lotes (hasta 50 archivos simultáneos)
- ✅ Genera dos archivos CSV:
  - `facturas_resumen.csv` - Una fila por factura
  - `facturas_detalle.csv` - Una fila por línea de producto/servicio
- ✅ Interfaz web responsive con Bootstrap 5
- ✅ Drag & drop para cargar archivos
- ✅ Validación de archivos XML
- ✅ Vista previa de resultados
- ✅ Descarga en archivo ZIP
- ✅ Encoding UTF-8 con BOM (compatible con Excel)
- ✅ Limpieza automática de archivos temporales

## Requisitos

- Python 3.9+
- Flask
- lxml
- pandas
- Werkzeug

## Instalación

1. Clonar el repositorio:
```bash
cd fac2csv
```

2. Crear entorno virtual:
```bash
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. Instalar dependencias:
```bash
pip install -r requirements.txt
```

## Uso

### Iniciar el servidor de desarrollo

```bash
source venv/bin/activate  # Si no está activado
python app.py
```

La aplicación estará disponible en: `http://localhost:5000`

### Uso desde la interfaz web

1. Abrir `http://localhost:5000` en el navegador
2. Seleccionar o arrastrar archivos XML de facturas DIAN
3. Hacer clic en "Procesar Facturas"
4. Descargar el archivo ZIP con los CSVs generados

### Uso programático

```python
from xml_parser import parse_single_invoice
from csv_generator import generate_summary_csv, generate_detail_csv

# Parsear una factura
invoice_data = parse_single_invoice('ruta/a/factura.xml')

# Generar CSVs
invoices = [invoice_data]  # Lista de facturas parseadas
generate_summary_csv(invoices, 'facturas_resumen.csv')
generate_detail_csv(invoices, 'facturas_detalle.csv')
```

## Estructura del Proyecto

```
fac2csv/
├── app.py                    # Aplicación Flask principal
├── xml_parser.py             # Parser XML para facturas DIAN
├── csv_generator.py          # Generador de archivos CSV
├── utils/
│   ├── validators.py         # Validación de archivos XML
│   └── file_manager.py       # Gestión de archivos temporales
├── templates/
│   ├── base.html            # Template base
│   ├── index.html           # Página de upload
│   └── results.html         # Página de resultados
├── static/
│   ├── css/style.css        # Estilos personalizados
│   └── js/main.js           # JavaScript frontend
├── uploads/                 # Directorio temporal para XMLs
├── outputs/                 # Directorio temporal para CSVs
├── requirements.txt         # Dependencias Python
└── README.md               # Esta documentación
```

## Campos Extraídos

### Resumen de Factura (`facturas_resumen.csv`)

**Información General:**
- numero_factura, prefijo, cufe
- fecha_emision, hora_emision, fecha_vencimiento
- periodo_inicio, periodo_fin

**Cliente:**
- cliente_nombre, cliente_nit, cliente_direccion
- cliente_codigo_postal, cliente_municipio

**Emisor:**
- emisor_nombre, emisor_nit, emisor_direccion

**Valores Monetarios:**
- subtotal, iva_porcentaje, iva_monto
- imp_consumo_voz, imp_consumo_datos
- descuentos_totales, total_pagar

### Detalle de Líneas (`facturas_detalle.csv`)

Incluye todos los campos de resumen + campos de línea:
- linea_numero, linea_descripcion
- linea_cantidad, linea_precio_unitario
- linea_descuento_porcentaje, linea_total

## Limitaciones

- **Extensión:** Solo archivos `.xml`
- **Tamaño:** Máximo 10MB por archivo
- **Cantidad:** Máximo 50 archivos simultáneos
- **Formato:** XML debe ser UBL 2.1 válido

## Desarrollo

### Ejecutar tests

```bash
source venv/bin/activate
python test_parser.py
```

### Producción

Para producción, usar un servidor WSGI como Gunicorn:

```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

## Deployment en DigitalOcean App Platform

Esta aplicación está lista para ser deployada en DigitalOcean App Platform.

### Opción 1: Deploy desde GitHub (Recomendado)

1. Hacer push del código a GitHub (ya configurado en este repositorio)
2. Ir a [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
3. Hacer clic en **"Create App"**
4. Seleccionar **"GitHub"** como fuente
5. Autorizar DigitalOcean a acceder a tu cuenta de GitHub
6. Seleccionar el repositorio: `zentratek/zentratek-fac2csv`
7. Seleccionar la rama: `main`
8. DigitalOcean detectará automáticamente el archivo `.do/app.yaml`
9. Revisar la configuración:
   - **Region:** NYC (o la más cercana a tus usuarios)
   - **Instance Size:** Basic XXS ($5/mes) - puedes escalar después
   - **Environment Variables:** Ya configuradas en app.yaml
10. Hacer clic en **"Create Resources"**
11. Esperar 5-10 minutos mientras DigitalOcean construye y deploya la app

### Opción 2: Deploy Manual con doctl CLI

```bash
# Instalar doctl
snap install doctl

# Autenticar
doctl auth init

# Crear app desde el spec
doctl apps create --spec .do/app.yaml
```

### Variables de Entorno (Opcional)

La aplicación usa estas variables de entorno (ya configuradas en `.do/app.yaml`):

- `FLASK_ENV`: `production` (obligatorio)
- `PORT`: Asignado automáticamente por DigitalOcean
- `MAX_CONTENT_LENGTH`: `524288000` (500MB para múltiples archivos)
- `SECRET_KEY`: (opcional) Generado automáticamente si no se configura

Para agregar variables personalizadas:
1. Ir a tu app en el panel de DigitalOcean
2. Settings → App-Level Environment Variables
3. Agregar las variables necesarias

### Auto-deploy

Con la configuración actual (`deploy_on_push: true`), cada push a la rama `main` disparará un deploy automático.

### Costos Estimados

- **Basic XXS:** ~$5/mes (512 MB RAM, 1 vCPU)
- **Basic XS:** ~$12/mes (1 GB RAM, 1 vCPU) - Recomendado para producción
- **Professional XS:** ~$25/mes (1 GB RAM, 2 vCPU) - Para alto tráfico

### Monitoreo

Después del deploy, puedes monitorear tu app en:
- Panel de DigitalOcean → Apps → zentratek-fac2csv
- Ver logs en tiempo real
- Métricas de CPU/RAM
- Historial de deployments

### Escalado

Para escalar la aplicación:
1. Ir a Settings → Scaling
2. Ajustar:
   - **Instance Size:** Basic XS o Professional XS
   - **Instance Count:** 2+ para alta disponibilidad
   - **Workers:** Ajustar en app.yaml (actualmente 2 workers, 4 threads)

## Logging

Los logs se generan en la consola con el siguiente formato:
```
YYYY-MM-DD HH:MM:SS - module_name - LEVEL - message
```

## Limpieza Automática

La aplicación limpia automáticamente archivos temporales (uploads y outputs) con más de 1 hora de antigüedad al inicio de cada petición.

## Referencias

- [DIAN - Facturación Electrónica](https://www.dian.gov.co/facturacionelectronica)
- [UBL 2.1 Specification](http://docs.oasis-open.org/ubl/UBL-2.1.html)
- [Flask Documentation](https://flask.palletsprojects.com/)

## Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.
