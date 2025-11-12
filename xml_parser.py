"""XML Parser for DIAN electronic invoices (UBL 2.1 format)."""

import logging
from typing import Dict, List, Any
from lxml import etree as ET

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# UBL 2.1 Namespaces used by DIAN invoices
NAMESPACES = {
    'cac': 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
    'cbc': 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
    'ext': 'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
    'sts': 'dian:gov:co:facturaelectronica:Structures-2-1',
    'ds': 'http://www.w3.org/2000/09/xmldsig#',
    'xades': 'http://uri.etsi.org/01903/v1.3.2#',
    'invoice': 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
    'attached': 'urn:oasis:names:specification:ubl:schema:xsd:AttachedDocument-2'
}


class ParseError(Exception):
    """Custom exception for XML parsing errors."""
    pass


def extract_embedded_invoice(xml_path: str) -> ET._Element:
    """Extract the embedded Invoice XML from AttachedDocument wrapper.

    DIAN invoices may come wrapped in an AttachedDocument with the actual
    invoice embedded in a CDATA section within cac:Attachment.

    Args:
        xml_path: Path to the XML file

    Returns:
        The Invoice root element

    Raises:
        ParseError: If XML cannot be parsed or invoice not found
    """
    try:
        # Parse the outer XML
        tree = ET.parse(xml_path)
        root = tree.getroot()

        # Check if this is already an Invoice document
        if root.tag.endswith('Invoice'):
            return root

        # Try to extract embedded invoice from AttachedDocument
        if root.tag.endswith('AttachedDocument'):
            # Look for the CDATA content in cac:Attachment/cac:ExternalReference/cbc:Description
            description_elem = root.find('.//cac:ExternalReference/cbc:Description', NAMESPACES)

            if description_elem is not None and description_elem.text:
                # Parse the embedded XML
                embedded_xml = description_elem.text.strip()
                embedded_root = ET.fromstring(embedded_xml.encode('utf-8'))

                if embedded_root.tag.endswith('Invoice'):
                    return embedded_root

        # If we get here, we couldn't find an invoice
        raise ParseError(f"Could not find Invoice element in {xml_path}")

    except ET.XMLSyntaxError as e:
        raise ParseError(f"XML syntax error in {xml_path}: {e}")
    except Exception as e:
        raise ParseError(f"Error extracting invoice from {xml_path}: {e}")


def safe_find_text(element: ET._Element, xpath: str, namespaces: Dict[str, str], default: str = '') -> str:
    """Safely extract text from an XML element.

    Args:
        element: The XML element to search in
        xpath: XPath expression
        namespaces: Namespace dictionary
        default: Default value if element not found

    Returns:
        Element text or default value
    """
    try:
        found = element.find(xpath, namespaces)
        return found.text.strip() if found is not None and found.text else default
    except Exception as e:
        logger.warning(f"Error finding element '{xpath}': {e}")
        return default


def safe_find_attribute(element: ET._Element, xpath: str, attr: str, namespaces: Dict[str, str], default: str = '') -> str:
    """Safely extract an attribute from an XML element.

    Args:
        element: The XML element to search in
        xpath: XPath expression
        attr: Attribute name
        namespaces: Namespace dictionary
        default: Default value if element/attribute not found

    Returns:
        Attribute value or default value
    """
    try:
        found = element.find(xpath, namespaces)
        return found.get(attr, default) if found is not None else default
    except Exception as e:
        logger.warning(f"Error finding attribute '{attr}' in '{xpath}': {e}")
        return default


def parse_invoice_general(invoice_root: ET._Element) -> Dict[str, Any]:
    """Extract general invoice information.

    Args:
        invoice_root: Invoice XML root element

    Returns:
        Dictionary with general invoice fields
    """
    data = {}

    try:
        # Basic invoice info
        data['numero_factura'] = safe_find_text(invoice_root, './/cbc:ID', NAMESPACES)

        # Extract prefix from CorporateRegistrationScheme
        data['prefijo'] = safe_find_text(
            invoice_root,
            './/cac:AccountingSupplierParty//cac:CorporateRegistrationScheme/cbc:ID',
            NAMESPACES
        )

        # CUFE
        data['cufe'] = safe_find_attribute(invoice_root, './/cbc:UUID', 'schemeName', NAMESPACES)
        if not data['cufe']:  # If schemeName not found, get the UUID value
            data['cufe'] = safe_find_text(invoice_root, './/cbc:UUID', NAMESPACES)

        # Dates and times
        data['fecha_emision'] = safe_find_text(invoice_root, './/cbc:IssueDate', NAMESPACES)
        issue_time = safe_find_text(invoice_root, './/cbc:IssueTime', NAMESPACES)
        # Extract just the time portion (HH:MM:SS)
        data['hora_emision'] = issue_time.split('-')[0].split('+')[0] if issue_time else ''

        data['fecha_vencimiento'] = safe_find_text(invoice_root, './/cbc:DueDate', NAMESPACES)

        # Billing period (if exists)
        data['periodo_inicio'] = safe_find_text(
            invoice_root,
            './/cac:InvoicePeriod/cbc:StartDate',
            NAMESPACES
        )
        data['periodo_fin'] = safe_find_text(
            invoice_root,
            './/cac:InvoicePeriod/cbc:EndDate',
            NAMESPACES
        )

    except Exception as e:
        logger.error(f"Error parsing general invoice info: {e}")

    return data


def parse_invoice_customer(invoice_root: ET._Element) -> Dict[str, Any]:
    """Extract customer information.

    Args:
        invoice_root: Invoice XML root element

    Returns:
        Dictionary with customer fields
    """
    data = {}

    try:
        customer = invoice_root.find('.//cac:AccountingCustomerParty/cac:Party', NAMESPACES)

        if customer is not None:
            # Customer name
            data['cliente_nombre'] = safe_find_text(
                customer,
                './/cac:PartyTaxScheme/cbc:RegistrationName',
                NAMESPACES
            )
            if not data['cliente_nombre']:
                data['cliente_nombre'] = safe_find_text(customer, './/cac:PartyName/cbc:Name', NAMESPACES)

            # Customer NIT/ID
            data['cliente_nit'] = safe_find_text(
                customer,
                './/cac:PartyTaxScheme/cbc:CompanyID',
                NAMESPACES
            )
            if not data['cliente_nit']:
                data['cliente_nit'] = safe_find_text(customer, './/cac:PartyIdentification/cbc:ID', NAMESPACES)

            # Customer address
            address = customer.find('.//cac:PhysicalLocation/cac:Address', NAMESPACES)
            if address is not None:
                data['cliente_direccion'] = safe_find_text(address, './/cac:AddressLine/cbc:Line', NAMESPACES)
                data['cliente_codigo_postal'] = safe_find_text(address, './/cbc:PostalZone', NAMESPACES)
                data['cliente_municipio'] = safe_find_text(address, './/cbc:CityName', NAMESPACES)
            else:
                data['cliente_direccion'] = ''
                data['cliente_codigo_postal'] = ''
                data['cliente_municipio'] = ''
        else:
            data['cliente_nombre'] = ''
            data['cliente_nit'] = ''
            data['cliente_direccion'] = ''
            data['cliente_codigo_postal'] = ''
            data['cliente_municipio'] = ''

    except Exception as e:
        logger.error(f"Error parsing customer info: {e}")

    return data


def parse_invoice_supplier(invoice_root: ET._Element) -> Dict[str, Any]:
    """Extract supplier/issuer information.

    Args:
        invoice_root: Invoice XML root element

    Returns:
        Dictionary with supplier fields
    """
    data = {}

    try:
        supplier = invoice_root.find('.//cac:AccountingSupplierParty/cac:Party', NAMESPACES)

        if supplier is not None:
            # Supplier name
            data['emisor_nombre'] = safe_find_text(
                supplier,
                './/cac:PartyTaxScheme/cbc:RegistrationName',
                NAMESPACES
            )
            if not data['emisor_nombre']:
                data['emisor_nombre'] = safe_find_text(supplier, './/cac:PartyName/cbc:Name', NAMESPACES)

            # Supplier NIT
            data['emisor_nit'] = safe_find_text(
                supplier,
                './/cac:PartyTaxScheme/cbc:CompanyID',
                NAMESPACES
            )
            if not data['emisor_nit']:
                data['emisor_nit'] = safe_find_text(supplier, './/cac:PartyIdentification/cbc:ID', NAMESPACES)

            # Supplier address
            address = supplier.find('.//cac:PhysicalLocation/cac:Address', NAMESPACES)
            if address is not None:
                data['emisor_direccion'] = safe_find_text(address, './/cac:AddressLine/cbc:Line', NAMESPACES)
            else:
                data['emisor_direccion'] = ''
        else:
            data['emisor_nombre'] = ''
            data['emisor_nit'] = ''
            data['emisor_direccion'] = ''

    except Exception as e:
        logger.error(f"Error parsing supplier info: {e}")

    return data


def parse_invoice_amounts(invoice_root: ET._Element) -> Dict[str, Any]:
    """Extract monetary amounts and taxes.

    Args:
        invoice_root: Invoice XML root element

    Returns:
        Dictionary with monetary fields
    """
    data = {}

    try:
        # Total amounts from LegalMonetaryTotal
        monetary = invoice_root.find('.//cac:LegalMonetaryTotal', NAMESPACES)

        if monetary is not None:
            data['subtotal'] = safe_find_text(monetary, './/cbc:TaxExclusiveAmount', NAMESPACES)
            data['descuentos_totales'] = safe_find_text(monetary, './/cbc:AllowanceTotalAmount', NAMESPACES)
            data['total_pagar'] = safe_find_text(monetary, './/cbc:PayableAmount', NAMESPACES)
        else:
            data['subtotal'] = '0.00'
            data['descuentos_totales'] = '0.00'
            data['total_pagar'] = '0.00'

        # IVA information from TaxTotal
        iva_found = False
        tax_totals = invoice_root.findall('.//cac:TaxTotal/cac:TaxSubtotal', NAMESPACES)

        for tax_subtotal in tax_totals:
            tax_id = safe_find_text(tax_subtotal, './/cac:TaxScheme/cbc:ID', NAMESPACES)

            if tax_id == '01':  # IVA
                data['iva_porcentaje'] = safe_find_text(tax_subtotal, './/cac:TaxCategory/cbc:Percent', NAMESPACES)
                data['iva_monto'] = safe_find_text(tax_subtotal, './/cbc:TaxAmount', NAMESPACES)
                iva_found = True
                break

        if not iva_found:
            data['iva_porcentaje'] = '0.00'
            data['iva_monto'] = '0.00'

        # Consumption taxes (voice and data) - usually not present, defaulting to 0
        data['imp_consumo_voz'] = '0.00'
        data['imp_consumo_datos'] = '0.00'

    except Exception as e:
        logger.error(f"Error parsing amounts: {e}")

    return data


def parse_invoice_lines(invoice_root: ET._Element) -> List[Dict[str, Any]]:
    """Extract invoice line items.

    Args:
        invoice_root: Invoice XML root element

    Returns:
        List of dictionaries with line item fields
    """
    lines = []

    try:
        invoice_lines = invoice_root.findall('.//cac:InvoiceLine', NAMESPACES)

        for line in invoice_lines:
            line_data = {}

            line_data['linea_numero'] = safe_find_text(line, './/cbc:ID', NAMESPACES)
            line_data['linea_descripcion'] = safe_find_text(line, './/cac:Item/cbc:Description', NAMESPACES)
            line_data['linea_cantidad'] = safe_find_text(line, './/cbc:InvoicedQuantity', NAMESPACES)

            # Unit price
            price_amount = safe_find_text(line, './/cac:Price/cbc:PriceAmount', NAMESPACES)
            line_data['linea_precio_unitario'] = price_amount

            # Line total
            line_data['linea_total'] = safe_find_text(line, './/cbc:LineExtensionAmount', NAMESPACES)

            # Discount percentage (if exists in AllowanceCharge)
            discount_elem = line.find('.//cac:AllowanceCharge[cbc:ChargeIndicator="false"]', NAMESPACES)
            if discount_elem is not None:
                discount_pct = safe_find_text(discount_elem, './/cbc:MultiplierFactorNumeric', NAMESPACES)
                line_data['linea_descuento_porcentaje'] = discount_pct
            else:
                line_data['linea_descuento_porcentaje'] = '0.00'

            lines.append(line_data)

    except Exception as e:
        logger.error(f"Error parsing invoice lines: {e}")

    return lines


def parse_single_invoice(xml_path: str) -> Dict[str, Any]:
    """Parse a single DIAN XML invoice and extract all required fields.

    Args:
        xml_path: Path to the XML invoice file

    Returns:
        Dictionary containing all invoice data including line items

    Raises:
        ParseError: If the invoice cannot be parsed
    """
    try:
        # Extract the actual Invoice element (may be embedded)
        invoice_root = extract_embedded_invoice(xml_path)

        # Parse all sections
        data = {}
        data.update(parse_invoice_general(invoice_root))
        data.update(parse_invoice_customer(invoice_root))
        data.update(parse_invoice_supplier(invoice_root))
        data.update(parse_invoice_amounts(invoice_root))

        # Parse line items separately
        data['lineas'] = parse_invoice_lines(invoice_root)

        logger.info(f"Successfully parsed invoice: {data.get('numero_factura', 'unknown')}")
        return data

    except ParseError:
        raise
    except Exception as e:
        raise ParseError(f"Unexpected error parsing {xml_path}: {e}")
