#!/bin/bash

# --- Configuration ---
MONITOR_USER="temperature_monitor_user"
MONITOR_GROUP="temperature_monitor_group"

# Directory for the script's operational logs (e.g., out.log)
SERVICE_LOG_DIR="/var/log/temperature-monitor"

# Directory for the temperature output data logs (used by run.sh)
DATA_LOG_DIR="/var/lib/temperature-monitor/data"

# Base directory where Python project repositories will be cloned
TOOLS_BASE_DIR="/usr/local/bin/tools"

# Python project repositories
declare -A PYTHON_REPOS
PYTHON_REPOS["cpu-temp"]="https://github.com/tugapse/cpu-temp.git"
PYTHON_REPOS["gpu-temp"]="https://github.com/tugapse/gpu-temp.git"

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

# Function to check if a command exists and provide installation guidance
check_tool_installed() {
    local tool_name="$1"
    local install_cmd="$2"
    if ! command -v "$tool_name" >/dev/null 2>&1; then
        log_error "Required tool '$tool_name' is not installed."
        log_error "Please install it using: $install_cmd"
        exit 1
    fi
    log_info "Tool '$tool_name' is installed."
}

# Function to create a directory and set permissions
setup_directory() {
    local dir_path="$1"
    local dir_description="$2"
    local permissions="$3" # New argument for custom permissions

    log_info "Checking and configuring the $dir_description directory: '$dir_path'..."

    # Check if the directory exists, otherwise try to create it
    if [ ! -d "$dir_path" ]; then
        log_info "Directory '$dir_path' not found. Attempting to create..."
        mkdir -p "$dir_path"
        if [ $? -eq 0 ]; then
            log_info "Directory '$dir_path' created successfully."
        else
            log_error "CRITICAL FAILURE: Failed to create directory '$dir_path'. Check parent directory permissions."
            exit 1 # Exit if directory cannot be created
        fi
    else
        log_warn "Directory '$dir_path' already exists. Skipping creation."
    fi

    log_info "Setting ownership and permissions for '$dir_path' to '$MONITOR_USER':'$MONITOR_GROUP'..."
    chown "$MONITOR_USER":"$MONITOR_GROUP" "$dir_path"
    if [ $? -ne 0 ]; then
        log_error "CRITICAL FAILURE: Failed to set ownership for '$dir_path'. Verify user/group '$MONITOR_USER':'$MONITOR_GROUP' exist and you have permissions to change ownership."
        exit 1 # Exit if ownership cannot be set
    fi

    chmod "$permissions" "$dir_path" # Use custom permissions
    if [ $? -ne 0 ]; then
        log_error "CRITICAL FAILURE: Failed to set permissions for '$dir_path'. Check current permissions and if the user has sufficient privileges."
        exit 1 # Exit if permissions cannot be set
    fi
    log_info "Permissions for '$dir_path' set successfully (owner: $MONITOR_USER, group: $MONITOR_GROUP, mode: $permissions)."
    log_info "You can verify permissions with: ls -ld $dir_path"
}

# Function to clone repository and set up venv
clone_and_setup_python_repo() {
    local repo_name="$1"
    local github_url="$2"
    local project_dir="$TOOLS_BASE_DIR/$repo_name"
    local venv_dir="$project_dir/.venv"
    local main_script="$project_dir/main.py" # Added for chmod
    local requirements_file="$project_dir/requirements.txt"

    log_info "Checking repository '$repo_name' at '$project_dir'..."
    if [ -d "$project_dir" ]; then
        log_warn "Repository '$repo_name' already exists at '$project_dir'. Skipping cloning."
    else
        log_info "Cloning '$github_url' to '$project_dir'..."
        unset GITHUB_TOKEN # Ensure no persistent GitHub token interferes
        unset GIT_SSH_COMMAND # Ensure it doesn't try SSH
        env -i HOME="/tmp" GIT_ASKPASS="" GIT_TERMINAL_PROMPT=0 git clone "$github_url" "$project_dir"
        if [ $? -ne 0 ]; then
            log_error "Failed to clone repository '$github_url'. Check network access and URL."
            exit 1
        fi
        log_info "Repository '$repo_name' cloned successfully."
    fi

    log_info "Setting up virtual environment for '$repo_name' at '$venv_dir'..."
    if [ -d "$venv_dir" ]; then
        log_warn "Virtual environment for '$repo_name' already exists at '$venv_dir'. Skipping creation."
    else
        python3 -m venv "$venv_dir"
        if [ $? -ne 0 ]; then
            log_error "Failed to create virtual environment for '$repo_name'. Ensure 'python3-venv' or similar package is installed."
            exit 1
        fi
        log_info "Virtual environment for '$repo_name' created."
    fi

    # Install dependencies
    if [ -f "$requirements_file" ]; then
        log_info "Installing dependencies for '$repo_name' from '$requirements_file'..."
        source "$venv_dir/bin/activate" # Temporarily activate venv for pip
        pip install -r "$requirements_file" --no-input --disable-pip-version-check
        if [ $? -ne 0 ]; then
            log_error "Failed to install dependencies for '$repo_name'. Check '$requirements_file' and log for detailed pip errors."
            deactivate
            exit 1
        fi
        deactivate # Deactivate venv
        log_info "Dependencies for '$repo_name' installed."
    else
        log_warn "requirements.txt file not found for '$repo_name'. Skipping dependency installation."
    fi

    # Set ownership for the service user (MONITOR_USER) for the repository and venv
    log_info "Setting ownership for '$repo_name' and its virtual environment to '$MONITOR_USER':'$MONITOR_GROUP'..."
    chown -R "$MONITOR_USER":"$MONITOR_GROUP" "$project_dir"
    if [ $? -ne 0 ]; then
        log_error "Failed to set ownership for '$project_dir'."
        exit 1
    fi

    # More specific permission adjustment:
    # 1. Set permissions for all files and directories within the cloned project.
    #    For directories, set them to 770. For files, 660.
    find "$project_dir" -type d -exec chmod 770 {} +
    find "$project_dir" -type f -exec chmod 660 {} +

    # 2. Ensure Python scripts (.py) and venv executables are executable by the group.
    #    This is crucial for the service user.
    chmod g+x "$project_dir"/main.py # Ensure main.py is executable by the group
    # Only if venv/bin exists and contains files
    if [ -d "$venv_dir/bin" ]; then
        chmod g+x "$venv_dir"/bin/* # Ensure venv/bin executables are executable by the group
    fi


    if [ $? -ne 0 ]; then
        log_error "Failed to set additional permissions for '$project_dir'."
        exit 1
    fi
    log_info "Ownership and permissions for '$repo_name' set."
}


# --- Main Script Logic ---

# Check if the script is run as root and if SUDO_USER is defined
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root. Please use 'sudo ./setup-service-users.sh'"
   exit 1
fi
if [[ -z "$SUDO_USER" ]]; then
    log_error "Could not determine the user who invoked sudo. Please run this script with 'sudo ./setup-service-users.sh'."
    exit 1
fi

log_info "Starting configuration for user '$MONITOR_USER' and log directories for user '$SUDO_USER'..."
log_info "Main data log path: $DATA_LOG_DIR" # Refers to the fixed system path now

# Pre-checks for necessary system tools
check_tool_installed "git" "sudo pacman -S git"
check_tool_installed "python3" "sudo pacman -S python"


# 1. Create the dedicated group
if getent group "$MONITOR_GROUP" > /dev/null; then
    log_info "Group '$MONITOR_GROUP' already exists. Skipping creation."
else
    log_info "Creating system group '$MONITOR_GROUP'..."
    groupadd --system "$MONITOR_GROUP"
    if [ $? -eq 0 ]; then
        log_info "Group '$MONITOR_GROUP' created successfully."
    else
        log_error "Failed to create group '$MONITOR_GROUP'."
        exit 1
    fi
fi

# 2. Create the dedicated user
if id -u "$MONITOR_USER" > /dev/null 2>&1; then
    log_info "User '$MONITOR_USER' already exists. Skipping creation."
else
    log_info "Creating system user '$MONITOR_USER'..."
    useradd --system --no-create-home --shell /sbin/nologin -g "$MONITOR_GROUP" "$MONITOR_USER"
    if [ $? -eq 0 ]; then
        log_info "User '$MONITOR_USER' created successfully."
    else
        log_error "Failed to create user '$MONITOR_USER'."
        exit 1
    fi
fi

# 3. Configure Service Log Directory (rwx for owner/group)
setup_directory "$SERVICE_LOG_DIR" "Service Log" "770"

# 4. Configure Main Data Log Path (rwx for owner/group, rx for others)
setup_directory "$DATA_LOG_DIR" "System Data Log" "775"

# 5. Configure Tools Base Directory
setup_directory "$TOOLS_BASE_DIR" "Tools Base" "770"

# 6. Clone and configure Python repositories to the tools directory
for REPO_KEY in "${!PYTHON_REPOS[@]}"; do
    clone_and_setup_python_repo "$REPO_KEY" "${PYTHON_REPOS[$REPO_KEY]}"
done

log_info "Configuration complete. User '$MONITOR_USER' should now have permissions for log and tools directories."
log_info "Python project repositories have been cloned to: '$TOOLS_BASE_DIR'"
log_info "Data logs will be stored in '$DATA_LOG_DIR'."
log_info "You can test the wrapper scripts manually (after service installation): sudo -u $MONITOR_USER /usr/local/bin/cpu-temp-wrapper.sh -s"
log_info "And: sudo -u $MONITOR_USER /usr/local/bin/gpu-temp-wrapper.sh -s"
