"""CSV Generator for DIAN invoice data."""

import csv
import logging
from typing import List, Dict, Any
import pandas as pd

logger = logging.getLogger(__name__)


class CSVGenerationError(Exception):
    """Custom exception for CSV generation errors."""
    pass


def format_decimal(value: Any) -> str:
    """Format a numeric value to decimal with 2 decimals and dot separator.

    Args:
        value: Numeric value (str, float, or int)

    Returns:
        Formatted string with 2 decimals
    """
    try:
        if value == '' or value is None:
            return '0.00'

        # Convert to float and format
        num_value = float(str(value).replace(',', ''))
        return f"{num_value:.2f}"
    except (ValueError, TypeError):
        logger.warning(f"Could not format value '{value}' as decimal, returning 0.00")
        return '0.00'


def generate_summary_csv(invoices: List[Dict[str, Any]], output_path: str) -> None:
    """Generate facturas_resumen.csv with one row per invoice.

    Args:
        invoices: List of parsed invoice dictionaries
        output_path: Path where CSV will be saved

    Raises:
        CSVGenerationError: If CSV cannot be generated
    """
    try:
        if not invoices:
            raise CSVGenerationError("No invoices to process")

        # Define column headers (in Spanish as per requirements)
        columns = [
            'numero_factura',
            'prefijo',
            'cufe',
            'fecha_emision',
            'hora_emision',
            'fecha_vencimiento',
            'periodo_inicio',
            'periodo_fin',
            'cliente_nombre',
            'cliente_nit',
            'cliente_direccion',
            'cliente_codigo_postal',
            'cliente_municipio',
            'emisor_nombre',
            'emisor_nit',
            'emisor_direccion',
            'subtotal',
            'iva_porcentaje',
            'iva_monto',
            'imp_consumo_voz',
            'imp_consumo_datos',
            'descuentos_totales',
            'total_pagar'
        ]

        # Prepare data rows
        rows = []
        for invoice in invoices:
            row = {}
            for col in columns:
                value = invoice.get(col, '')

                # Format decimal fields
                if col in ['subtotal', 'iva_porcentaje', 'iva_monto', 'imp_consumo_voz',
                          'imp_consumo_datos', 'descuentos_totales', 'total_pagar']:
                    value = format_decimal(value)

                row[col] = value

            rows.append(row)

        # Create DataFrame
        df = pd.DataFrame(rows, columns=columns)

        # Write to CSV with UTF-8 BOM for Excel compatibility
        df.to_csv(
            output_path,
            index=False,
            encoding='utf-8-sig',
            quoting=csv.QUOTE_NONNUMERIC,
            sep=','
        )

        logger.info(f"Generated summary CSV with {len(rows)} invoices: {output_path}")

    except Exception as e:
        raise CSVGenerationError(f"Error generating summary CSV: {e}")


def generate_detail_csv(invoices: List[Dict[str, Any]], output_path: str) -> None:
    """Generate facturas_detalle.csv with one row per invoice line item.

    Each row includes all summary fields plus line-specific fields.

    Args:
        invoices: List of parsed invoice dictionaries
        output_path: Path where CSV will be saved

    Raises:
        CSVGenerationError: If CSV cannot be generated
    """
    try:
        if not invoices:
            raise CSVGenerationError("No invoices to process")

        # Define column headers (summary fields + line fields)
        columns = [
            # Summary fields
            'numero_factura',
            'prefijo',
            'cufe',
            'fecha_emision',
            'hora_emision',
            'fecha_vencimiento',
            'periodo_inicio',
            'periodo_fin',
            'cliente_nombre',
            'cliente_nit',
            'cliente_direccion',
            'cliente_codigo_postal',
            'cliente_municipio',
            'emisor_nombre',
            'emisor_nit',
            'emisor_direccion',
            'subtotal',
            'iva_porcentaje',
            'iva_monto',
            'imp_consumo_voz',
            'imp_consumo_datos',
            'descuentos_totales',
            'total_pagar',
            # Line-specific fields
            'linea_numero',
            'linea_descripcion',
            'linea_cantidad',
            'linea_precio_unitario',
            'linea_descuento_porcentaje',
            'linea_total'
        ]

        # Prepare data rows (expand lines)
        rows = []
        for invoice in invoices:
            # Get line items (if any)
            lines = invoice.get('lineas', [])

            # If no lines, create one row with empty line fields
            if not lines:
                row = {}
                for col in columns:
                    if col.startswith('linea_'):
                        row[col] = ''
                    else:
                        value = invoice.get(col, '')
                        # Format decimal fields
                        if col in ['subtotal', 'iva_porcentaje', 'iva_monto', 'imp_consumo_voz',
                                  'imp_consumo_datos', 'descuentos_totales', 'total_pagar']:
                            value = format_decimal(value)
                        row[col] = value
                rows.append(row)
            else:
                # Create one row per line item
                for line in lines:
                    row = {}
                    for col in columns:
                        if col.startswith('linea_'):
                            # Line-specific field
                            value = line.get(col, '')
                            # Format decimal fields
                            if col in ['linea_cantidad', 'linea_precio_unitario',
                                      'linea_descuento_porcentaje', 'linea_total']:
                                value = format_decimal(value)
                            row[col] = value
                        else:
                            # Summary field
                            value = invoice.get(col, '')
                            # Format decimal fields
                            if col in ['subtotal', 'iva_porcentaje', 'iva_monto', 'imp_consumo_voz',
                                      'imp_consumo_datos', 'descuentos_totales', 'total_pagar']:
                                value = format_decimal(value)
                            row[col] = value
                    rows.append(row)

        # Create DataFrame
        df = pd.DataFrame(rows, columns=columns)

        # Write to CSV with UTF-8 BOM for Excel compatibility
        df.to_csv(
            output_path,
            index=False,
            encoding='utf-8-sig',
            quoting=csv.QUOTE_NONNUMERIC,
            sep=','
        )

        logger.info(f"Generated detail CSV with {len(rows)} line items: {output_path}")

    except Exception as e:
        raise CSVGenerationError(f"Error generating detail CSV: {e}")
