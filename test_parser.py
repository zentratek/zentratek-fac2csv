"""Test script to validate XML parsing and CSV generation."""

import os
import glob
from xml_parser import parse_single_invoice, ParseError
from csv_generator import generate_summary_csv, generate_detail_csv, CSVGenerationError


def test_invoices():
    """Test parsing all XML files in facturas/ directory."""
    # Find all XML files
    xml_files = glob.glob('facturas/*.xml')

    if not xml_files:
        print("No XML files found in facturas/ directory")
        return

    print(f"Found {len(xml_files)} XML file(s) to process\n")

    # Parse all invoices
    invoices = []
    errors = []

    for xml_file in xml_files:
        print(f"Processing: {xml_file}")
        try:
            invoice_data = parse_single_invoice(xml_file)
            invoices.append(invoice_data)
            print(f"  ✓ Successfully parsed invoice: {invoice_data.get('numero_factura', 'N/A')}")
            print(f"    Emisor: {invoice_data.get('emisor_nombre', 'N/A')}")
            print(f"    Cliente: {invoice_data.get('cliente_nombre', 'N/A')}")
            print(f"    Total: ${invoice_data.get('total_pagar', '0.00')}")
            print(f"    Líneas: {len(invoice_data.get('lineas', []))}")
        except ParseError as e:
            errors.append((xml_file, str(e)))
            print(f"  ✗ Error: {e}")
        print()

    # Report results
    print(f"\n{'='*60}")
    print(f"PARSING RESULTS:")
    print(f"  Successful: {len(invoices)}")
    print(f"  Errors: {len(errors)}")
    print(f"{'='*60}\n")

    if errors:
        print("ERRORS:")
        for filename, error in errors:
            print(f"  {filename}: {error}")
        print()

    # Generate CSVs if we have data
    if invoices:
        print("Generating CSV files...")
        try:
            # Generate summary CSV
            summary_path = 'outputs/facturas_resumen.csv'
            generate_summary_csv(invoices, summary_path)
            print(f"  ✓ Generated: {summary_path}")

            # Generate detail CSV
            detail_path = 'outputs/facturas_detalle.csv'
            generate_detail_csv(invoices, detail_path)
            print(f"  ✓ Generated: {detail_path}")

            print(f"\n{'='*60}")
            print("SUCCESS! CSVs generated successfully.")
            print(f"{'='*60}")

        except CSVGenerationError as e:
            print(f"  ✗ CSV Generation Error: {e}")
    else:
        print("No invoices to generate CSVs from.")


if __name__ == '__main__':
    test_invoices()
