"""Flask application for converting DIAN XML invoices to CSV."""

import os
import logging
from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, send_file, flash, session
from werkzeug.utils import secure_filename

from xml_parser import parse_single_invoice, ParseError
from csv_generator import generate_summary_csv, generate_detail_csv, CSVGenerationError
from utils.validators import validate_file, validate_files_count, ValidationError
from utils.file_manager import (
    ensure_directories,
    cleanup_old_files,
    create_zip_archive,
    sanitize_filename,
    extract_xml_from_zip
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Secret key configuration
# In production, use environment variable; in development, generate random key
app.secret_key = os.environ.get('SECRET_KEY', os.urandom(24))

# Configuration
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'outputs'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['OUTPUT_FOLDER'] = OUTPUT_FOLDER

# Max content length from environment (for production) or default 10MB
MAX_CONTENT_MB = int(os.environ.get('MAX_CONTENT_LENGTH', 10 * 1024 * 1024))
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_MB

# Ensure directories exist
ensure_directories(UPLOAD_FOLDER, OUTPUT_FOLDER)


@app.before_request
def before_request():
    """Clean up old files before each request."""
    cleanup_old_files(app.config['UPLOAD_FOLDER'])
    cleanup_old_files(app.config['OUTPUT_FOLDER'])


@app.route('/')
def index():
    """Render the main upload form page."""
    return render_template('index.html')


@app.route('/upload', methods=['POST'])
def upload_files():
    """Handle file upload and processing."""
    try:
        # Check if files were uploaded
        if 'files' not in request.files:
            flash('No se seleccionaron archivos.', 'error')
            return redirect(url_for('index'))

        files = request.files.getlist('files')

        # Validate file count
        try:
            validate_files_count(len(files))
        except ValidationError as e:
            flash(str(e), 'error')
            return redirect(url_for('index'))

        # Process files
        uploaded_files = []
        validation_errors = []
        parsing_errors = []
        parsed_invoices = []
        xml_files_to_process = []

        for file in files:
            if file.filename == '':
                continue

            # Sanitize filename
            filename = sanitize_filename(file.filename)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_filename = f"{timestamp}_{filename}"
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)

            # Save file
            file.save(file_path)
            uploaded_files.append({'original': filename, 'path': file_path})

            # Check if it's a ZIP file
            if filename.lower().endswith('.zip'):
                try:
                    # Extract XML files from ZIP
                    extracted_files = extract_xml_from_zip(file_path, app.config['UPLOAD_FOLDER'])
                    logger.info(f"Extracted {len(extracted_files)} XML files from {filename}")

                    # Add extracted files to processing list
                    for extracted_file in extracted_files:
                        xml_files_to_process.append({
                            'path': extracted_file,
                            'filename': os.path.basename(extracted_file),
                            'from_zip': filename
                        })

                except IOError as e:
                    validation_errors.append({'file': filename, 'error': str(e)})
                    logger.error(f"ZIP extraction error for {filename}: {e}")
                    continue
            else:
                # Regular XML file
                xml_files_to_process.append({
                    'path': file_path,
                    'filename': filename,
                    'from_zip': None
                })

        # Process all XML files (both direct uploads and extracted from ZIPs)
        for xml_file_info in xml_files_to_process:
            file_path = xml_file_info['path']
            filename = xml_file_info['filename']

            # Validate file (skip extension check for extracted files)
            if xml_file_info['from_zip']:
                # For extracted files, only validate size, well-formedness, and namespace
                from utils.validators import validate_file_size, validate_xml_wellformed, validate_ubl_namespace
                try:
                    validate_file_size(file_path)
                    validate_xml_wellformed(file_path)
                    validate_ubl_namespace(file_path)
                    is_valid = True
                    error_msg = ""
                except ValidationError as e:
                    is_valid = False
                    error_msg = str(e)
            else:
                # For direct uploads, run full validation
                is_valid, error_msg = validate_file(file_path, filename)

            if not is_valid:
                source = f"{filename} (from {xml_file_info['from_zip']})" if xml_file_info['from_zip'] else filename
                validation_errors.append({'file': source, 'error': error_msg})
                continue

            # Parse invoice
            try:
                invoice_data = parse_single_invoice(file_path)
                parsed_invoices.append(invoice_data)
                source = f"{filename} (from {xml_file_info['from_zip']})" if xml_file_info['from_zip'] else filename
                logger.info(f"Successfully parsed: {source}")
            except ParseError as e:
                source = f"{filename} (from {xml_file_info['from_zip']})" if xml_file_info['from_zip'] else filename
                parsing_errors.append({'file': source, 'error': str(e)})
                logger.error(f"Parse error for {source}: {e}")

        # Check if we have any valid invoices
        if not parsed_invoices:
            flash('No se pudo procesar ninguna factura. Revise los errores.', 'error')
            session['validation_errors'] = validation_errors
            session['parsing_errors'] = parsing_errors
            return redirect(url_for('results'))

        # Generate CSVs
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            summary_filename = f"facturas_resumen_{timestamp}.csv"
            detail_filename = f"facturas_detalle_{timestamp}.csv"

            summary_path = os.path.join(app.config['OUTPUT_FOLDER'], summary_filename)
            detail_path = os.path.join(app.config['OUTPUT_FOLDER'], detail_filename)

            generate_summary_csv(parsed_invoices, summary_path)
            generate_detail_csv(parsed_invoices, detail_path)

            # Create ZIP archive
            zip_filename = f"facturas_{timestamp}.zip"
            zip_path = os.path.join(app.config['OUTPUT_FOLDER'], zip_filename)
            create_zip_archive([summary_path, detail_path], zip_path)

            # Store results in session
            session['zip_file'] = zip_filename
            session['summary_file'] = summary_filename
            session['detail_file'] = detail_filename
            session['processed_count'] = len(parsed_invoices)
            session['total_count'] = len([f for f in files if f.filename != ''])
            session['validation_errors'] = validation_errors
            session['parsing_errors'] = parsing_errors

            flash(f'¡Procesamiento exitoso! {len(parsed_invoices)} factura(s) convertida(s).', 'success')
            return redirect(url_for('results'))

        except CSVGenerationError as e:
            flash(f'Error generando archivos CSV: {e}', 'error')
            logger.error(f"CSV generation error: {e}")
            return redirect(url_for('index'))

    except Exception as e:
        logger.error(f"Unexpected error in upload: {e}")
        flash(f'Error inesperado: {e}', 'error')
        return redirect(url_for('index'))


@app.route('/results')
def results():
    """Display processing results and download options."""
    # Get data from session
    zip_file = session.get('zip_file')
    summary_file = session.get('summary_file')
    detail_file = session.get('detail_file')
    processed_count = session.get('processed_count', 0)
    total_count = session.get('total_count', 0)
    validation_errors = session.get('validation_errors', [])
    parsing_errors = session.get('parsing_errors', [])

    # Load CSV previews (first 10 rows)
    summary_preview = []
    detail_preview = []

    if summary_file:
        summary_path = os.path.join(app.config['OUTPUT_FOLDER'], summary_file)
        if os.path.exists(summary_path):
            try:
                import pandas as pd
                df = pd.read_csv(summary_path, nrows=10)
                summary_preview = df.to_dict('records')
            except Exception as e:
                logger.error(f"Error loading summary preview: {e}")

    if detail_file:
        detail_path = os.path.join(app.config['OUTPUT_FOLDER'], detail_file)
        if os.path.exists(detail_path):
            try:
                import pandas as pd
                df = pd.read_csv(detail_path, nrows=10)
                detail_preview = df.to_dict('records')
            except Exception as e:
                logger.error(f"Error loading detail preview: {e}")

    return render_template(
        'results.html',
        zip_file=zip_file,
        processed_count=processed_count,
        total_count=total_count,
        validation_errors=validation_errors,
        parsing_errors=parsing_errors,
        summary_preview=summary_preview,
        detail_preview=detail_preview
    )


@app.route('/download/<filename>')
def download_file(filename):
    """Download a generated file."""
    try:
        file_path = os.path.join(app.config['OUTPUT_FOLDER'], secure_filename(filename))

        if not os.path.exists(file_path):
            flash('Archivo no encontrado.', 'error')
            return redirect(url_for('index'))

        return send_file(
            file_path,
            as_attachment=True,
            download_name=filename
        )

    except Exception as e:
        logger.error(f"Error downloading file: {e}")
        flash(f'Error descargando archivo: {e}', 'error')
        return redirect(url_for('results'))


@app.route('/clear')
def clear_session():
    """Clear session and redirect to index."""
    session.clear()
    return redirect(url_for('index'))


if __name__ == '__main__':
    # Get port from environment (for cloud platforms) or default to 5000
    port = int(os.environ.get('PORT', 5000))
    # Only enable debug in development
    debug = os.environ.get('FLASK_ENV', 'development') == 'development'
    app.run(debug=debug, host='0.0.0.0', port=port)
