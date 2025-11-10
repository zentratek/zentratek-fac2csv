// Frontend validation and interactions for fac2csv

document.addEventListener('DOMContentLoaded', function() {
    const fileInput = document.getElementById('fileInput');
    const dropZone = document.getElementById('dropZone');
    const fileList = document.getElementById('fileList');
    const fileListContent = document.getElementById('fileListContent');
    const submitBtn = document.getElementById('submitBtn');
    const uploadForm = document.getElementById('uploadForm');

    // Only run if we're on the upload page
    if (!fileInput || !dropZone) {
        return;
    }

    let selectedFiles = [];

    // File input change handler
    fileInput.addEventListener('change', function(e) {
        handleFiles(this.files);
    });

    // Drag and drop handlers
    dropZone.addEventListener('click', function(e) {
        if (e.target !== fileInput) {
            fileInput.click();
        }
    });

    dropZone.addEventListener('dragover', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.classList.add('dragover');
    });

    dropZone.addEventListener('dragleave', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.classList.remove('dragover');
    });

    dropZone.addEventListener('drop', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.classList.remove('dragover');

        const files = e.dataTransfer.files;
        handleFiles(files);
    });

    // Form submit handler - add loading state
    if (uploadForm) {
        uploadForm.addEventListener('submit', function(e) {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Procesando...';
        });
    }

    /**
     * Handle file selection
     */
    function handleFiles(files) {
        // Convert FileList to Array and filter XML files
        const fileArray = Array.from(files).filter(file => {
            if (!file.name.toLowerCase().endsWith('.xml')) {
                showAlert(`Archivo ignorado: "${file.name}" (solo se permiten archivos .xml)`, 'warning');
                return false;
            }
            if (file.size > 10 * 1024 * 1024) {
                showAlert(`Archivo ignorado: "${file.name}" (excede 10MB)`, 'warning');
                return false;
            }
            return true;
        });

        // Add to selected files
        selectedFiles = selectedFiles.concat(fileArray);

        // Check max files limit
        if (selectedFiles.length > 50) {
            showAlert('Máximo 50 archivos permitidos. Se han seleccionado los primeros 50.', 'warning');
            selectedFiles = selectedFiles.slice(0, 50);
        }

        // Update file input with selected files
        updateFileInput();

        // Display file list
        displayFileList();

        // Enable submit button if files are selected
        submitBtn.disabled = selectedFiles.length === 0;
    }

    /**
     * Display list of selected files
     */
    function displayFileList() {
        if (selectedFiles.length === 0) {
            fileList.style.display = 'none';
            return;
        }

        fileList.style.display = 'block';
        fileListContent.innerHTML = '';

        selectedFiles.forEach((file, index) => {
            const fileItem = createFileListItem(file, index);
            fileListContent.appendChild(fileItem);
        });
    }

    /**
     * Create a file list item element
     */
    function createFileListItem(file, index) {
        const item = document.createElement('div');
        item.className = 'list-group-item file-list-item';

        const fileInfo = document.createElement('div');
        fileInfo.className = 'file-info';

        const icon = document.createElement('i');
        icon.className = 'bi bi-file-earmark-text file-icon';

        const nameSpan = document.createElement('span');
        nameSpan.className = 'file-name';
        nameSpan.textContent = file.name;

        const sizeSpan = document.createElement('span');
        sizeSpan.className = 'file-size ms-2';
        sizeSpan.textContent = `(${formatFileSize(file.size)})`;

        fileInfo.appendChild(icon);
        fileInfo.appendChild(nameSpan);
        fileInfo.appendChild(sizeSpan);

        const removeBtn = document.createElement('i');
        removeBtn.className = 'bi bi-x-circle file-remove';
        removeBtn.title = 'Eliminar';
        removeBtn.addEventListener('click', function() {
            removeFile(index);
        });

        item.appendChild(fileInfo);
        item.appendChild(removeBtn);

        return item;
    }

    /**
     * Remove file from selection
     */
    function removeFile(index) {
        selectedFiles.splice(index, 1);
        updateFileInput();
        displayFileList();
        submitBtn.disabled = selectedFiles.length === 0;
    }

    /**
     * Update file input with current selection
     */
    function updateFileInput() {
        // Create a new DataTransfer object to update file input
        const dataTransfer = new DataTransfer();
        selectedFiles.forEach(file => {
            dataTransfer.items.add(file);
        });
        fileInput.files = dataTransfer.files;
    }

    /**
     * Format file size for display
     */
    function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';

        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));

        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }

    /**
     * Show alert message
     */
    function showAlert(message, type = 'info') {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
        alertDiv.role = 'alert';
        alertDiv.innerHTML = `
            <i class="bi bi-${type === 'warning' ? 'exclamation-triangle' : 'info-circle'}"></i>
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;

        const container = document.querySelector('.container');
        container.insertBefore(alertDiv, container.firstChild);

        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            alertDiv.remove();
        }, 5000);
    }
});
