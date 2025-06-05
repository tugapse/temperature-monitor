#!/bin/bash
# Script to perform a full reset and reinstallation of the temperature monitoring service.
# This script is interactive and will ask for user confirmation at each step.

# --- ANSI Color Codes ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m' # Added yellow for warnings/info
COLOR_NC='\033[0m' # No Color (reset)

# --- Logging Functions ---
log_info() {
    echo -e "${COLOR_GREEN}[INFO] $1${COLOR_NC}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARNING] $1${COLOR_NC}"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR] $1${COLOR_NC}" >&2
}

# --- Confirmation Function ---
confirm_action() {
    local message="$1"
    read -p "$(log_warn "$message (Y/n)? ")" response
    # Treat empty response (Enter) as 'yes' by default
    response=${response:-Y} # If response is empty, set it to 'Y'
    case "$response" in
        [yY]|[yY][eE][sS])
            true
            ;;
        *)
            false
            ;;
    esac
}

# --- Main Script Logic ---

log_info "Initiating the FULL RESET process for the Temperature Monitoring Service."
log_info "This script will:
1. Stop and remove the existing systemd service and its executable scripts.
2. Clean up log directories, tools directory, and remove the dedicated system user/group.
3. Reconfigure the user/group, create directories, clone Python repositories, and install dependencies.
4. Reinstall and start the systemd service.
5. Display the final service status."

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root. Please use 'sudo ./reset.sh'"
   exit 1
fi
if [[ -z "$SUDO_USER" ]]; then
    log_error "Could not determine the user who invoked sudo. Please run this script with 'sudo ./reset.sh'."
    exit 1
fi

log_info "Preparation complete. The process will proceed in the current directory: $(pwd)"

# ==============================================================================
# 1. Fully clean up any previous installation
# ==============================================================================
echo ""
log_info "STEP 1/5: Removing the service and all previously installed components..."
log_info "This includes stopping and disabling the systemd service, and deleting all scripts in /usr/local/bin/."
if confirm_action "Continue with service removal"; then
    sudo ./temperature_monitor_service_manager.sh remove
    if [ $? -ne 0 ]; then
        log_error "Failed to remove the service. Please check the errors above and resolve them before continuing."
        exit 1
    fi
    log_info "Service and scripts removed successfully."
else
    log_warn "Service removal cancelled. Exiting."
    exit 0
fi

echo ""
log_info "STEP 2/5: Cleaning up log directories, tools directory, and removing the dedicated user/group."
log_info "This will delete old temperature logs and cloned repositories, as well as the 'temperature_monitor_user' user."
if confirm_action "Continue with directory and user cleanup"; then
    sudo ./cleanup-setup-users.sh
    # Ensure the tools directory is completely clean, in case a failed clone left something behind.
    # cleanup-setup-users.sh already handles this, but it's an extra precaution.
    sudo rm -rf /usr/local/bin/tools
    if [ $? -ne 0 ]; then
        log_error "Failed to clean up directories and users. Please check the errors above and resolve them before continuing."
        exit 1
    fi
    log_info "Directories and users cleaned up successfully."
else
    log_warn "Directory and user cleanup cancelled. Exiting."
    exit 0
fi

# ==============================================================================
# 2. Execute the setup script (reconfigures user, creates dirs, clones repos, installs venv)
# ==============================================================================
echo ""
log_info "STEP 3/5: Reconfiguring the system."
log_info "This step will re-create the service user and group, log and tools directories, CLONE the Python repositories (cpu-temp and gpu-temp) from GitHub, and install their dependencies (requirements.txt)."
log_info "Data logs will be stored in '/var/lib/temperature-monitor/data'."
if confirm_action "Continue with system configuration"; then
    sudo ./setup-service-users.sh
    if [ $? -ne 0 ]; then
        log_error "System configuration failed. Please check the errors above and resolve them."
        exit 1
    fi
    log_info "System configuration completed successfully."
else
    log_warn "System configuration cancelled. Exiting."
    exit 0
fi

# ==============================================================================
# 3. Ensure executable permissions for all local scripts
# ==============================================================================
echo ""
log_info "STEP 4/5: Ensuring executable permissions for all local scripts."
log_info "This is a safeguard to ensure the scripts can be copied and executed by the service."
if confirm_action "Continue setting executable permissions"; then
    chmod +x *.sh
    if [ $? -ne 0 ]; then
        log_error "Failed to set executable permissions. Please check for errors."
        exit 1
    fi
    log_info "Executable permissions set successfully."
else
    log_warn "Setting executable permissions cancelled. Exiting."
    exit 0
fi

# ==============================================================================
# 4. Install the service
# ==============================================================================
echo ""
log_info "STEP 5/5: Installing and starting the monitoring service."
log_info "This step will copy the scripts to /usr/local/bin/, configure systemd, and start the service."
if confirm_action "Continue with service installation"; then
    sudo ./temperature_monitor_service_manager.sh install
    if [ $? -ne 0 ]; then
        log_error "Failed to install the service. Please check the errors above and resolve them."
        exit 1
    fi
    log_info "Service installed and started successfully."
else
    log_warn "Service installation cancelled. Exiting."
    exit 0
fi

echo ""
log_info "FULL RESET COMPLETE."
log_info "You can now check the service status:"
sudo systemctl status temperature-monitor.service

echo ""
log_info "To view real-time logs, use:"
log_info "sudo journalctl -u temperature-monitor.service -f"
echo ""
log_info "To view CPU temperature logs, use:"
log_info "sudo tail -f /var/lib/temperature-monitor/data/cpu_temp_output.log"
echo ""
log_info "To view GPU temperature logs, use:"
log_info "sudo tail -f /var/lib/temperature-monitor/data/gpu_temp_output.log"