#!/bin/bash

# --- Configuration ---
SERVICE_NAME="temperature-monitor.service"
SERVICE_FILE_SOURCE="./$SERVICE_NAME"
SERVICE_FILE_DEST="/etc/systemd/system/$SERVICE_NAME"

RUNNER_SCRIPT_SOURCE="./run.sh"
RUNNER_SCRIPT_DEST_NAME="temperature-monitor-runner.sh"
RUNNER_SCRIPT_PATH="/usr/local/bin/$RUNNER_SCRIPT_DEST_NAME"

WRAPPER_CPU_SOURCE="./cpu-temp-wrapper.sh"
WRAPPER_CPU_DEST_NAME="cpu-temp-wrapper.sh"
WRAPPER_CPU_PATH="/usr/local/bin/$WRAPPER_CPU_DEST_NAME"

WRAPPER_GPU_SOURCE="./gpu-temp-wrapper.sh"
WRAPPER_GPU_DEST_NAME="gpu-temp-wrapper.sh"
WRAPPER_GPU_PATH="/usr/local/bin/$WRAPPER_GPU_DEST_NAME"

PYTHON_SCRIPT_RUNNER_SOURCE="./python_script_runner.sh"
PYTHON_SCRIPT_RUNNER_DEST="/usr/local/bin/python_script_runner.sh"



# --- Functions ---

# Function to log messages to stdout
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# --- Main Script Logic ---

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root. Please use 'sudo ./temperature_monitor_service_manager.sh [install|remove]'"
   exit 1
fi
# SUDO_USER is not used for data log path here, but kept for consistency with setup-service-users.sh if needed later.
# if [[ -z "$SUDO_USER" ]]; then
#     log_error "Could not determine the user who invoked sudo. Please run this script with 'sudo ./temperature_monitor_service_manager.sh'."
#     exit 1
# fi

# Function to install the service
install_service() {
    log_info "Attempting to install '$SERVICE_NAME' and associated scripts..."

    # Validate that source files exist
    if [ ! -f "$RUNNER_SCRIPT_SOURCE" ]; then
        log_error "Main runner script source file ('$RUNNER_SCRIPT_SOURCE') not found."
        log_error "Ensure 'run.sh' is in the same directory as this script."
        exit 1
    fi
    if [ ! -f "$SERVICE_FILE_SOURCE" ]; then
        log_error "Service file '$SERVICE_FILE_SOURCE' not found in current directory."
        log_error "Ensure '$SERVICE_NAME' is in the same directory as this script."
        exit 1
    fi
    if [ ! -f "$WRAPPER_CPU_SOURCE" ]; then
        log_error "CPU wrapper script source file ('$WRAPPER_CPU_SOURCE') not found."
        log_error "Ensure 'cpu-temp-wrapper.sh' is in the same directory as this script."
        exit 1
    fi
    if [ ! -f "$WRAPPER_GPU_SOURCE" ]; then
        log_error "GPU wrapper script source file ('$WRAPPER_GPU_SOURCE') not found."
        log_error "Ensure 'gpu-temp-wrapper.sh' is in the same directory as this script."
        exit 1
    fi
    if [ ! -f "$PYTHON_SCRIPT_RUNNER_SOURCE" ]; then
        log_error "Python script runner source file ('$PYTHON_SCRIPT_RUNNER_SOURCE') not found."
        log_error "Ensure 'python_script_runner.sh' is in the same directory as this script."
        exit 1
    fi

    # Copy and rename the main runner script
    log_info "Copying '$RUNNER_SCRIPT_SOURCE' to '$RUNNER_SCRIPT_PATH' and renaming..."
    cp "$RUNNER_SCRIPT_SOURCE" "$RUNNER_SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        log_error "Failed to copy main runner script. Exiting."
        exit 1
    fi
    log_info "Setting executable permissions for '$RUNNER_SCRIPT_PATH'..."
    chmod +x "$RUNNER_SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        log_error "Failed to set executable permissions for runner script. Exiting."
        exit 1
    fi

    # Copy and set permissions for wrapper scripts
    log_info "Copying '$WRAPPER_CPU_SOURCE' to '$WRAPPER_CPU_PATH'..."
    cp "$WRAPPER_CPU_SOURCE" "$WRAPPER_CPU_PATH"
    if [ $? -ne 0 ]; then log_error "Failed to copy CPU wrapper script. Exiting."; exit 1; fi
    chmod +x "$WRAPPER_CPU_PATH"
    if [ $? -ne 0 ]; then log_error "Failed to set executable permissions for CPU wrapper. Exiting."; exit 1; fi

    log_info "Copying '$WRAPPER_GPU_SOURCE' to '$WRAPPER_GPU_PATH'..."
    cp "$WRAPPER_GPU_SOURCE" "$WRAPPER_GPU_PATH"
    if [ $? -ne 0 ]; then log_error "Failed to copy GPU wrapper script. Exiting."; exit 1; fi
    chmod +x "$WRAPPER_GPU_PATH"
    if [ $? -ne 0 ]; then log_error "Failed to set executable permissions for GPU wrapper. Exiting."; exit 1; fi

    # Copy and set permissions for common logic script
    log_info "Copying '$PYTHON_SCRIPT_RUNNER_SOURCE' to '$PYTHON_SCRIPT_RUNNER_DEST'..."
    cp "$PYTHON_SCRIPT_RUNNER_SOURCE" "$PYTHON_SCRIPT_RUNNER_DEST"
    if [ $? -ne 0 ]; then log_error "Failed to copy Python runner script. Exiting."; exit 1; fi
    chmod +x "$PYTHON_SCRIPT_RUNNER_DEST" # May need to be executable for 'source'
    if [ $? -ne 0 ]; then log_error "Failed to set executable permissions for Python script runner. Exiting."; exit 1; fi


    log_info "Copying '$SERVICE_NAME' to '$SERVICE_FILE_DEST'..."
    cp "$SERVICE_FILE_SOURCE" "$SERVICE_FILE_DEST"
    if [ $? -ne 0 ]; then
        log_error "Failed to copy service file. Exiting."
        exit 1
    fi

 
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload
    if [ $? -ne 0 ]; then
        log_error "Failed to reload systemd daemon. Exiting."
        exit 1
    fi

    log_info "Enabling '$SERVICE_NAME' to start on boot..."
    systemctl enable "$SERVICE_NAME"
    if [ $? -ne 0 ]; then
        log_error "Failed to enable service. Exiting."
    fi

    log_info "Starting '$SERVICE_NAME' immediately..."
    systemctl start "$SERVICE_NAME"
    if [ $? -ne 0 ]; then
        log_error "Failed to start service. Check 'journalctl -u $SERVICE_NAME' for errors."
        exit 1
    fi

    log_info "'$SERVICE_NAME' installed and started successfully."
    log_info "You can check its status with: sudo systemctl status $SERVICE_NAME"
    log_info "And view its logs with: sudo journalctl -u $SERVICE_NAME -f"
}

# Function to remove the service
remove_service() {
    log_info "Attempting to remove '$SERVICE_NAME' and associated scripts..."

    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "Stopping '$SERVICE_NAME'..."
        systemctl stop "$SERVICE_NAME"
        if [ $? -ne 0 ]; then
            log_error "Failed to stop service. Continuing with removal."
        fi
    else
        log_info "'$SERVICE_NAME' is not active."
    fi

    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        log_info "Disabling '$SERVICE_NAME'..."
        systemctl disable "$SERVICE_NAME"
        if [ $? -ne 0 ]; then
            log_error "Failed to disable service. Continuing with removal."
        fi
    else
        log_info "'$SERVICE_NAME' is not enabled."
    fi

    if [ -f "$SERVICE_FILE_DEST" ]; then
        log_info "Deleting service file '$SERVICE_FILE_DEST'..."
        rm "$SERVICE_FILE_DEST"
        if [ $? -ne 0 ]; then
            log_error "Failed to delete service file. Manual removal may be needed."
        fi
    else
        log_info "Service file '$SERVICE_FILE_DEST' not found. Skipping deletion."
    fi

    # Remove main runner script
    if [ -f "$RUNNER_SCRIPT_PATH" ]; then
        log_info "Deleting runner script '$RUNNER_SCRIPT_PATH'..."
        rm "$RUNNER_SCRIPT_PATH"
        if [ $? -ne 0 ]; then
            log_error "Failed to delete runner script. Manual removal may be needed."
        fi
    else
        log_info "Runner script '$RUNNER_SCRIPT_PATH' not found. Skipping deletion."
    fi

    # Remove wrapper scripts
    if [ -f "$WRAPPER_CPU_PATH" ]; then
        log_info "Deleting CPU wrapper script '$WRAPPER_CPU_PATH'..."
        rm "$WRAPPER_CPU_PATH"
        if [ $? -ne 0 ]; then log_error "Failed to delete CPU wrapper. Manual removal may be needed."; fi
    else
        log_info "CPU wrapper script '$WRAPPER_CPU_PATH' not found. Skipping deletion."
    fi

    if [ -f "$WRAPPER_GPU_PATH" ]; then
        log_info "Deleting GPU wrapper script '$WRAPPER_GPU_PATH'..."
        rm "$WRAPPER_GPU_PATH"
        if [ $? -ne 0 ]; then log_error "Failed to delete GPU wrapper. Manual removal may be needed."; fi
    else
        log_info "GPU wrapper script '$WRAPPER_GPU_PATH' not found. Skipping deletion."
    fi

    # Remove common logic script
    if [ -f "$PYTHON_SCRIPT_RUNNER_DEST" ]; then
        log_info "Deleting Python runner script '$PYTHON_SCRIPT_RUNNER_DEST'..."
        rm "$PYTHON_SCRIPT_RUNNER_DEST"
        if [ $? -ne 0 ]; then log_error "Failed to delete Python script runner. Manual removal may be needed."; fi
    else
        log_info "Python script runner '$PYTHON_SCRIPT_RUNNER_DEST' not found. Skipping deletion."
    fi

    log_info "Reloading systemd daemon..."
    systemctl daemon-reload
    if [ $? -ne 0 ]; then
        log_error "Failed to reload systemd daemon."
    fi

    log_info "'$SERVICE_NAME' removed successfully."
}

# Main script logic based on arguments
case "$1" in
    install)
        install_service
        ;;
    remove)
        remove_service
        ;;
    *)
        log_error "Usage: sudo ./temperature_monitor_service_manager.sh [install|remove]"
        exit 1
        ;;
esac
