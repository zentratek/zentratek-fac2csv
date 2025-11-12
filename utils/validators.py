"""File validation utilities."""

import os
import logging
from typing import Tuple
from lxml import etree as ET

logger = logging.getLogger(__name__)

# File constraints
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB in bytes
ALLOWED_EXTENSIONS = ['.xml', '.zip']
MAX_FILES = 50


class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


def validate_file_extension(filename: str) -> bool:
    """Validate that file has .xml or .zip extension.

    Args:
        filename: Name of the file

    Returns:
        True if extension is valid

    Raises:
        ValidationError: If extension is not .xml or .zip
    """
    if not any(filename.lower().endswith(ext) for ext in ALLOWED_EXTENSIONS):
        raise ValidationError(f"Invalid file extension. Only {', '.join(ALLOWED_EXTENSIONS)} files are allowed.")
    return True


def validate_file_size(file_path: str) -> bool:
    """Validate that file size is within limits.

    Args:
        file_path: Path to the file

    Returns:
        True if file size is valid

    Raises:
        ValidationError: If file size exceeds limit
    """
    try:
        file_size = os.path.getsize(file_path)
        if file_size > MAX_FILE_SIZE:
            raise ValidationError(f"File size ({file_size} bytes) exceeds maximum allowed ({MAX_FILE_SIZE} bytes).")
        if file_size == 0:
            raise ValidationError("File is empty.")
        return True
    except OSError as e:
        raise ValidationError(f"Error checking file size: {e}")


def validate_xml_wellformed(file_path: str) -> bool:
    """Validate that XML file is well-formed.

    Args:
        file_path: Path to the XML file

    Returns:
        True if XML is well-formed

    Raises:
        ValidationError: If XML is malformed
    """
    try:
        ET.parse(file_path)
        return True
    except ET.XMLSyntaxError as e:
        raise ValidationError(f"XML syntax error: {e}")
    except Exception as e:
        raise ValidationError(f"Error parsing XML: {e}")


def validate_ubl_namespace(file_path: str) -> bool:
    """Validate that XML contains UBL 2.1 namespace.

    Args:
        file_path: Path to the XML file

    Returns:
        True if UBL namespace is present

    Raises:
        ValidationError: If UBL namespace not found
    """
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()

        # Check for UBL namespaces
        ubl_namespaces = [
            'urn:oasis:names:specification:ubl:schema:xsd',
            'urn:oasis:names:specification:ubl'
        ]

        root_namespace = root.tag.split('}')[0].strip('{') if '}' in root.tag else ''

        if not any(ubl_ns in root_namespace for ubl_ns in ubl_namespaces):
            raise ValidationError("File does not appear to be a UBL 2.1 document.")

        return True
    except ET.XMLSyntaxError as e:
        raise ValidationError(f"XML syntax error: {e}")
    except ValidationError:
        raise
    except Exception as e:
        raise ValidationError(f"Error validating namespace: {e}")


def validate_file(file_path: str, filename: str) -> Tuple[bool, str]:
    """Run all validations on a file.

    Args:
        file_path: Path to the file
        filename: Original filename

    Returns:
        Tuple of (is_valid, error_message). error_message is empty if valid.
    """
    try:
        validate_file_extension(filename)
        validate_file_size(file_path)
        validate_xml_wellformed(file_path)
        validate_ubl_namespace(file_path)

        logger.info(f"File validated successfully: {filename}")
        return (True, "")

    except ValidationError as e:
        logger.warning(f"Validation failed for {filename}: {e}")
        return (False, str(e))
    except Exception as e:
        logger.error(f"Unexpected validation error for {filename}: {e}")
        return (False, f"Unexpected error: {e}")


def validate_files_count(count: int) -> bool:
    """Validate that number of files is within limits.

    Args:
        count: Number of files

    Returns:
        True if count is valid

    Raises:
        ValidationError: If count exceeds limit
    """
    if count == 0:
        raise ValidationError("No files provided.")
    if count > MAX_FILES:
        raise ValidationError(f"Too many files. Maximum allowed: {MAX_FILES}, provided: {count}.")
    return True
