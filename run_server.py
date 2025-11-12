"""
Production server using Waitress WSGI server for Windows.

This module provides a production-ready server for the Zentratek FAC2CSV application.
It uses Waitress (pure Python WSGI server) which is recommended for Windows deployments.
"""

import os
import sys
import logging
from pathlib import Path
from dotenv import load_dotenv

# Configure logging
log_dir = Path(__file__).parent / 'logs'
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / 'app.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

# Load environment variables from .env file
env_path = Path(__file__).parent / '.env'
if env_path.exists():
    load_dotenv(env_path)
    logger.info(f"Loaded environment variables from {env_path}")
else:
    logger.warning(f".env file not found at {env_path}")

# Import Flask app after loading environment
try:
    from app import app
    logger.info("Successfully imported Flask application")
except ImportError as e:
    logger.error(f"Failed to import Flask app: {e}")
    sys.exit(1)


def run_production_server():
    """
    Start the production server using Waitress.

    Configuration is loaded from environment variables:
    - HOST: Server host (default: 0.0.0.0)
    - PORT: Server port (default: 5000)
    - THREADS: Number of threads (default: 4)
    """
    try:
        from waitress import serve
    except ImportError:
        logger.error("Waitress is not installed. Run: pip install waitress")
        sys.exit(1)

    # Get configuration from environment
    host = os.getenv('HOST', '0.0.0.0')
    port = int(os.getenv('PORT', 5000))
    threads = int(os.getenv('THREADS', 4))

    logger.info("=" * 60)
    logger.info("Starting Zentratek FAC2CSV Production Server")
    logger.info(f"Host: {host}")
    logger.info(f"Port: {port}")
    logger.info(f"Threads: {threads}")
    logger.info(f"Environment: {os.getenv('FLASK_ENV', 'production')}")
    logger.info("=" * 60)

    try:
        serve(
            app,
            host=host,
            port=port,
            threads=threads,
            url_scheme='http'
        )
    except Exception as e:
        logger.error(f"Server failed to start: {e}")
        sys.exit(1)


if __name__ == '__main__':
    run_production_server()
