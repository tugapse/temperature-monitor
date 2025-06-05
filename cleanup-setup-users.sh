#!/bin/bash
# Script to revert all changes made by setup-service-users.sh.
# This includes deleting the dedicated user/group and associated directories.

# --- Configuration (MUST match setup-service-users.sh) ---
MONITOR_USER="temperature_monitor_user"
MONITOR_GROUP="temperature_monitor_group"

SERVICE_LOG_DIR="/var/log/temperature-monitor"
DATA_LOG_DIR="/var/lib/temperature-monitor/data" # Now only one data path
TOOLS_BASE_DIR="/usr/local/bin/tools" # Base directory for tools

# --- ANSI Color Codes ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m' # Added yellow for warnings/info
COLOR_NC='\033[0m' # No Color (reset)

# --- Functions ---

# Function to log messages to stdout
log_info() {
    echo -e "${COLOR_GREEN}[INFO] $1${COLOR_NC}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARNING] $1${COLOR_NC}"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR] $1${COLOR_NC}" >&2
}

# --- Main Script Logic ---

# Check if the script is run as root and if SUDO_USER is defined
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root. Please use 'sudo ./cleanup-setup-users.sh'"
   exit 1
fi
if [[ -z "$SUDO_USER" ]]; then
    log_error "Could not determine the user who invoked sudo. Please run this script with 'sudo ./cleanup-setup-users.sh'."
    exit 1
fi

log_info "Starting cleanup of configuration for user '$MONITOR_USER' and associated directories..."

# 1. Remove Directories
log_info "Attempting to remove log and tools directories..."

# Remove Service Log Directory
if [ -d "$SERVICE_LOG_DIR" ]; then
    log_info "Removing service log directory: '$SERVICE_LOG_DIR'..."
    rm -rf "$SERVICE_LOG_DIR"
    if [ $? -eq 0 ]; then
        log_info "Directory '$SERVICE_LOG_DIR' removed successfully."
    else
        log_error "Failed to remove directory '$SERVICE_LOG_DIR'. Manual removal may be needed."
    fi
else
    log_warn "Service log directory '$SERVICE_LOG_DIR' not found. Skipping removal."
fi

# Remove System Data Log Path
if [ -d "$DATA_LOG_DIR" ]; then
    log_info "Removing system data log directory: '$DATA_LOG_DIR'..."
    rm -rf "$DATA_LOG_DIR"
    if [ $? -eq 0 ]; then
        log_info "Directory '$DATA_LOG_DIR' removed successfully."
    else
        log_error "Failed to remove directory '$DATA_LOG_DIR'. Manual removal may be needed."
    fi
else
    log_warn "System data log directory '$DATA_LOG_DIR' not found. Skipping removal."
fi

# Remove Tools Base Directory (where repositories are cloned)
if [ -d "$TOOLS_BASE_DIR" ]; then
    log_info "Removing tools base directory: '$TOOLS_BASE_DIR'..."
    rm -rf "$TOOLS_BASE_DIR"
    if [ $? -eq 0 ]; then
        log_info "Directory '$TOOLS_BASE_DIR' removed successfully."
    else
        log_error "Failed to remove directory '$TOOLS_BASE_DIR'. Manual removal may be needed."
    fi
else
    log_warn "Tools base directory '$TOOLS_BASE_DIR' not found. Skipping removal."
fi

# 2. Remove Dedicated User
if id -u "$MONITOR_USER" > /dev/null 2>&1; then
    log_info "Removing system user '$MONITOR_USER'..."
    userdel "$MONITOR_USER"
    if [ $? -eq 0 ]; then
        log_info "User '$MONITOR_USER' removed successfully."
    else
        log_error "Failed to remove user '$MONITOR_USER'. Manual removal may be needed."
    fi
else
    log_warn "User '$MONITOR_USER' not found. Skipping removal."
fi

# 3. Remove Dedicated Group
if getent group "$MONITOR_GROUP" > /dev/null; then
    log_info "Removing system group '$MONITOR_GROUP'..."
    groupdel "$MONITOR_GROUP"
    if [ $? -eq 0 ]; then
        log_info "Group '$MONITOR_GROUP' removed successfully."
    else
        log_error "Failed to remove group '$MONITOR_GROUP'. Manual removal may be needed."
    fi
else
    log_warn "Group '$MONITOR_GROUP' not found. Skipping removal."
fi

log_info "Cleanup complete. Your system should now be reverted from setup-service-users.sh changes."
log_info "If errors occurred above, manual verification/cleanup might be needed."
