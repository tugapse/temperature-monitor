# This script is designed to be 'sourced' by other wrapper scripts.
# It provides a function to activate a virtual environment and execute a Python script,
# assuming the project and its virtual environment are already configured in TOOLS_BASE_DIR.

# --- Common Configuration ---
# Base directory where Python repositories are cloned.
# This should match TOOLS_BASE_DIR in setup-service-users.sh.
COMMON_TOOLS_BASE_DIR="/usr/local/bin/tools"

# --- Common Functions ---

# Function to log messages (for the internal logging of the sourcing wrapper scripts)
# Requires the 'REPO_NAME' variable to be defined in the sourcing script.
log_wrapper_message() {
    local type="$1"
    local message="$2"
    # Output to stderr can be captured by run.sh and directed to out.log
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WRAPPER-${REPO_NAME}-$type] $message" >&2
}

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# Main function to run a Python project
# This function should be called by individual wrapper scripts.
# Requires the 'REPO_NAME' variable to be defined in the sourcing script before calling this function.
# Arguments: "$@" - all arguments passed to the original wrapper script.
run_python_project() {
    # Derived paths based on REPO_NAME
    local project_dir="$COMMON_TOOLS_BASE_DIR/$REPO_NAME"
    local venv_dir="$project_dir/.venv"
    local main_script="$project_dir/main.py"

    log_wrapper_message "DEBUG" "Project Path: $project_dir"
    log_wrapper_message "DEBUG" "Venv Path: $venv_dir"
    log_wrapper_message "DEBUG" "Main Script Path: $main_script"
    log_wrapper_message "DEBUG" "Current user: $(whoami)"
    log_wrapper_message "DEBUG" "Current PATH: $PATH"

    # --- Pre-execution Checks ---
    # Ensure essential tools are available (extra robustness check)
    if ! command_exists python3; then
        log_wrapper_message "ERROR" "'python3' is not installed. Please install python to continue (e.g., sudo pacman -S python)."
        exit 1
    fi

    # Check if the project directory and virtual environment exist
    if [ ! -d "$project_dir" ]; then
        log_wrapper_message "ERROR" "Python project directory '$project_dir' not found. It should have been cloned and configured by 'setup-service-users.sh'."
        exit 1
    fi
    if [ ! -d "$venv_dir" ]; then
        log_wrapper_message "ERROR" "Python virtual environment '$venv_dir' not found inside project '$project_dir'. It should have been created by 'setup-service-users.sh'."
        exit 1
    fi
    if [ ! -f "$main_script" ]; then
        log_wrapper_message "ERROR" "Main Python script '$main_script' not found. Verify the repository was cloned correctly by 'setup-service-users.sh'."
        exit 1
    fi

    # Check venv and main script permissions
    if [ ! -r "$venv_dir/bin/activate" ]; then
        log_wrapper_message "ERROR" "Virtual environment activation file '$venv_dir/bin/activate' is not readable. Check permissions."
        exit 1
    fi
    if [ ! -x "$venv_dir/bin/python" ]; then
        log_wrapper_message "ERROR" "Virtual environment Python executable '$venv_dir/bin/python' is not executable. Check permissions."
        exit 1
    fi
    if [ ! -r "$main_script" ]; then
        log_wrapper_message "ERROR" "Main Python script '$main_script' is not readable. Check permissions."
        exit 1
    fi


    # --- Activate Virtual Environment ---
    log_wrapper_message "INFO" "Activating virtual environment for execution."
    # IMPORTANT: Using 'source' directly is preferred when running from a script
    # that is itself executed by bash (like a systemd service running a bash script).
    source "$venv_dir/bin/activate"
    if [ $? -ne 0 ]; then
        log_wrapper_message "ERROR" "CRITICAL Failure activating virtual environment at '$venv_dir/bin/activate'. This might be due to permissions or a limited bash environment."
        exit 1
    fi

    # --- Execute Main Python Script ---
    log_wrapper_message "INFO" "Executing '$main_script' with arguments: '$@'"
    python "$main_script" "$@"
    local python_script_exit_code=$? # Capture the exit code of the Python script

    # --- Deactivate Virtual Environment ---
    deactivate
    log_wrapper_message "INFO" "Virtual environment deactivated."

    return $python_script_exit_code # Return the Python script's exit code
}
