# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flask web application to convert Colombian DIAN electronic invoices (XML format, UBL 2.1) to CSV files.

**Project Status:** Greenfield - No code implemented yet

**Technology Stack:**
- Python 3.9+ with Flask, lxml, pandas
- Bootstrap 5 for UI
- UBL 2.1 XML standard (OASIS)

---

## Project Architecture

```
fac2csv/
├── app.py                    # Flask app + routes
├── xml_parser.py             # Core: XML parsing logic
├── csv_generator.py          # CSV generation from parsed data
├── utils/
│   ├── validators.py         # XML file validation
│   └── file_manager.py       # Temporary file cleanup
├── templates/
│   ├── base.html
│   ├── index.html           # Upload form
│   └── results.html         # Results + download
├── static/
│   ├── css/style.css
│   └── js/main.js           # Frontend validation
├── uploads/                 # Temp directory (auto-cleanup)
├── outputs/                 # Temp directory (auto-cleanup)
└── requirements.txt
```

**Reference Files:**
- `XML_BEC481550444.xml` - Example DIAN invoice (if available)
- `RepGrafica_BEC481550444.pdf` - Visual reference (if available)

---

## Development Commands

```bash
# Setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run development server
export FLASK_ENV=development
python app.py

# Run tests
pytest tests/ -v
```

---

## UBL 2.1 Namespaces (Critical for XML Parsing)

DIAN invoices use these UBL namespaces - must be registered correctly in lxml:

```python
NAMESPACES = {
    'cac': 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
    'cbc': 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
    'ext': 'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
    'sts': 'dian:gov:co:facturaelectronica:Structures-2-1',
    # Add others as discovered in example XML
}
```

**XPath usage example:**
```python
root.find('.//cbc:IssueDate', NAMESPACES)
root.findall('.//cac:InvoiceLine', NAMESPACES)
```

---

## CSV Output Specifications

The application generates **two CSV files** from each XML:

### 1. facturas_resumen.csv (Invoice Summary)

One row per invoice with these fields:

**General:** `numero_factura`, `prefijo`, `cufe`, `fecha_emision` (YYYY-MM-DD), `hora_emision` (HH:MM:SS), `fecha_vencimiento`, `periodo_inicio`, `periodo_fin`

**Client:** `cliente_nombre`, `cliente_nit`, `cliente_direccion`, `cliente_codigo_postal`, `cliente_municipio`

**Issuer:** `emisor_nombre`, `emisor_nit`, `emisor_direccion`

**Amounts:** `subtotal`, `iva_porcentaje`, `iva_monto`, `imp_consumo_voz`, `imp_consumo_datos`, `descuentos_totales`, `total_pagar`

### 2. facturas_detalle.csv (Line Items Detail)

One row per line item. Includes **all summary fields** + line-specific fields:

**Line fields:** `linea_numero`, `linea_descripcion`, `linea_cantidad`, `linea_precio_unitario`, `linea_descuento_porcentaje`, `linea_total`

### CSV Format Requirements

- **Encoding:** UTF-8 with BOM (Excel compatibility)
- **Separator:** Comma (`,`)
- **Decimals:** Always use dot (`.`) - format: `1234.56` (2 decimals, no thousand separators)
- **Quote character:** Double quotes (`"`)
- **Headers:** Spanish field names as listed above

---

## Core Functionality

### File Upload & Validation

**Limits:**
- File extension: `.xml` only
- Max size: 10MB per file
- Max files: 50 simultaneous uploads
- XML must be well-formed (validate with lxml)
- UBL 2.1 namespace must be present

**Security:**
- Sanitize filenames (use `werkzeug.utils.secure_filename`)
- Validate MIME type (not just extension)
- Store uploads/outputs outside `static/` directory
- Auto-cleanup files older than 1 hour

### XML Parsing (xml_parser.py)

**Core function signature:**
```python
def parse_single_invoice(xml_path: str) -> dict:
    """Parse a DIAN XML invoice.

    Returns:
        dict with all fields (use empty string for missing values)
    """
```

**Implementation notes:**
- Wrap each field extraction in try-except
- Return default values (empty string or 0) for missing fields
- Use Python's `logging` module (not print statements)
- Custom exception: `ParseError` for unrecoverable errors

### CSV Generation (csv_generator.py)

**Core functions:**
```python
def generate_summary_csv(invoices: list[dict], output_path: str) -> None:
    """Generate facturas_resumen.csv"""

def generate_detail_csv(invoices: list[dict], output_path: str) -> None:
    """Generate facturas_detalle.csv with line items expanded"""
```

**Use pandas for CSV generation:**
```python
df.to_csv(path, index=False, encoding='utf-8-sig',
          quoting=csv.QUOTE_NONNUMERIC)
```

### Flask Routes

- `GET /` - Upload form
- `POST /upload` - Process XMLs, generate CSVs
- `GET /results` - Show results + preview
- `GET /download` - Download ZIP with both CSVs

---

## Code Style Conventions

**Python:**
- Follow PEP 8
- Use Google-style docstrings
- Type hints required for all public functions
- Use `logging` module (never use `print()`)

**Error Handling:**
- Define custom exceptions: `ValidationError`, `ParseError`, `CSVGenerationError`
- Never expose stack traces to users
- Log complete errors server-side, show friendly messages in UI

**Example:**
```python
def parse_invoice_date(root: ET.Element, namespaces: dict) -> str:
    """Extract invoice issue date.

    Args:
        root: XML root element
        namespaces: UBL namespace dictionary

    Returns:
        Date in YYYY-MM-DD format, or empty string if not found
    """
    try:
        date_elem = root.find('.//cbc:IssueDate', namespaces)
        return date_elem.text if date_elem is not None else ''
    except Exception as e:
        logging.error(f"Error parsing date: {e}")
        return ''
```

## Implementation Workflow

**Start with XML analysis:** Always read the example XML file first (`XML_BEC481550444.xml`) to understand the actual structure before implementing parsers.

**Development approach:**
1. Implement and test each function incrementally
2. Validate each change with the example XML
3. Ask before making assumptions about unclear XML structures

**Common tasks:**
- Analyze XML structure and show field mappings
- Implement extraction functions for specific fields
- Create Flask routes for file upload
- Generate CSV from parsed data
- Add error handling for edge cases

---

## Key Technical Details

**Decimal formatting:** Always use dot (`.`) as decimal separator, 2 decimals required (`1234.56`), no thousand separators in CSV output.

**Temporary file cleanup:** Implement auto-cleanup for files older than 1 hour in `uploads/` and `outputs/` directories. Can be done via scheduled task or at request start.

**Testing criteria:**
- [ ] Processes example XML correctly
- [ ] Generates both CSVs with all required fields
- [ ] Excel opens CSVs without encoding issues
- [ ] Handles multiple files (up to 50) without errors
- [ ] Clear error reporting for parse failures

---

## References

- DIAN: Colombian electronic invoice specifications
- UBL 2.1: http://docs.oasis-open.org/ubl/UBL-2.1.html
- Flask: https://flask.palletsprojects.com/
- lxml: https://lxml.de/tutorial.html
