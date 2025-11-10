"""File management utilities."""

import os
import logging
import time
import zipfile
from typing import List
from werkzeug.utils import secure_filename

logger = logging.getLogger(__name__)

# Cleanup threshold (in seconds)
CLEANUP_AGE = 3600  # 1 hour


def sanitize_filename(filename: str) -> str:
    """Sanitize filename for safe storage.

    Args:
        filename: Original filename

    Returns:
        Sanitized filename
    """
    return secure_filename(filename)


def ensure_directories(*directories: str) -> None:
    """Ensure that directories exist, create if they don't.

    Args:
        *directories: Variable number of directory paths
    """
    for directory in directories:
        if not os.path.exists(directory):
            os.makedirs(directory, exist_ok=True)
            logger.info(f"Created directory: {directory}")


def cleanup_old_files(directory: str, max_age_seconds: int = CLEANUP_AGE) -> int:
    """Remove files older than specified age from directory.

    Args:
        directory: Directory to clean
        max_age_seconds: Maximum file age in seconds (default: 1 hour)

    Returns:
        Number of files deleted
    """
    if not os.path.exists(directory):
        return 0

    deleted_count = 0
    current_time = time.time()

    try:
        for filename in os.listdir(directory):
            file_path = os.path.join(directory, filename)

            # Skip directories and .gitkeep files
            if os.path.isdir(file_path) or filename == '.gitkeep':
                continue

            # Check file age
            file_age = current_time - os.path.getmtime(file_path)

            if file_age > max_age_seconds:
                try:
                    os.remove(file_path)
                    deleted_count += 1
                    logger.info(f"Deleted old file: {file_path}")
                except OSError as e:
                    logger.error(f"Error deleting file {file_path}: {e}")

    except Exception as e:
        logger.error(f"Error during cleanup of {directory}: {e}")

    if deleted_count > 0:
        logger.info(f"Cleaned up {deleted_count} old file(s) from {directory}")

    return deleted_count


def create_zip_archive(csv_files: List[str], output_path: str) -> str:
    """Create a ZIP archive containing CSV files.

    Args:
        csv_files: List of CSV file paths to include
        output_path: Path where ZIP file will be created

    Returns:
        Path to the created ZIP file

    Raises:
        IOError: If ZIP creation fails
    """
    try:
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for csv_file in csv_files:
                if os.path.exists(csv_file):
                    # Add file with just its basename (no path)
                    zipf.write(csv_file, os.path.basename(csv_file))
                else:
                    logger.warning(f"CSV file not found, skipping: {csv_file}")

        logger.info(f"Created ZIP archive: {output_path}")
        return output_path

    except Exception as e:
        logger.error(f"Error creating ZIP archive: {e}")
        raise IOError(f"Failed to create ZIP archive: {e}")


def delete_file(file_path: str) -> bool:
    """Safely delete a file.

    Args:
        file_path: Path to file to delete

    Returns:
        True if file was deleted, False otherwise
    """
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            logger.debug(f"Deleted file: {file_path}")
            return True
        return False
    except Exception as e:
        logger.error(f"Error deleting file {file_path}: {e}")
        return False


def extract_xml_from_zip(zip_path: str, extract_to: str) -> List[str]:
    """Extract XML files from a ZIP archive.

    Args:
        zip_path: Path to ZIP file
        extract_to: Directory to extract files to

    Returns:
        List of paths to extracted XML files

    Raises:
        IOError: If extraction fails or no XML files found
    """
    extracted_files = []

    try:
        # Ensure extraction directory exists
        ensure_directories(extract_to)

        with zipfile.ZipFile(zip_path, 'r') as zipf:
            # Get list of XML files in the archive
            xml_files = [f for f in zipf.namelist() if f.lower().endswith('.xml') and not f.startswith('__MACOSX/')]

            if not xml_files:
                raise IOError("No XML files found in ZIP archive")

            # Extract only XML files
            for xml_file in xml_files:
                # Skip directories
                if xml_file.endswith('/'):
                    continue

                # Extract file
                extracted_path = zipf.extract(xml_file, extract_to)

                # If file was in subdirectory, move it to root of extract_to
                if os.path.dirname(xml_file):
                    base_name = os.path.basename(xml_file)
                    new_path = os.path.join(extract_to, sanitize_filename(base_name))

                    # Move file to root directory
                    if extracted_path != new_path:
                        os.rename(extracted_path, new_path)
                        extracted_path = new_path

                extracted_files.append(extracted_path)
                logger.info(f"Extracted XML file: {os.path.basename(extracted_path)}")

        logger.info(f"Extracted {len(extracted_files)} XML file(s) from {os.path.basename(zip_path)}")
        return extracted_files

    except zipfile.BadZipFile:
        logger.error(f"Invalid ZIP file: {zip_path}")
        raise IOError("Invalid ZIP file format")
    except Exception as e:
        logger.error(f"Error extracting ZIP file {zip_path}: {e}")
        raise IOError(f"Failed to extract ZIP file: {e}")


def get_file_info(file_path: str) -> dict:
    """Get information about a file.

    Args:
        file_path: Path to file

    Returns:
        Dictionary with file information
    """
    try:
        stat = os.stat(file_path)
        return {
            'name': os.path.basename(file_path),
            'size': stat.st_size,
            'modified': stat.st_mtime,
            'exists': True
        }
    except Exception as e:
        logger.error(f"Error getting file info for {file_path}: {e}")
        return {
            'name': os.path.basename(file_path),
            'exists': False,
            'error': str(e)
        }
