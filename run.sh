#!/bin/bash

# Get the directory where this script (temperature-monitor-runner.sh) is located.
# This ensures that COMMAND1 and COMMAND2 are called from their actual location,
# assuming they are in the same directory (e.g., /usr/local/bin/).
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Configuration
# Directory for the script's own operational logs (e.g., out.log)
SERVICE_LOG_DIR="/var/log/temperature-monitor"

# Directory for the actual temperature output data logs (e.g., cpu_temp_output.log, gpu_temp_output.log)
# For simplicity and reliability with system services, all data logs will now go to a system-wide path.
DATA_LOG_DIR="/var/lib/temperature-monitor/data"

# Time to wait between loops, configurable by environment variable.
# If TEMPERATURE_MONITOR_INTERVAL_MINUTES is set, it will be used.
# Otherwise, it defaults to 10 minutes (600 seconds).
DEFAULT_INTERVAL_MINUTES=10
INTERVAL_MINUTES=${TEMPERATURE_MONITOR_INTERVAL_MINUTES:-$DEFAULT_INTERVAL_MINUTES}
SLEEP_SECONDS=$((INTERVAL_MINUTES * 60))

# Dynamically construct full paths for your wrapper scripts using SCRIPT_DIR.
COMMAND1="$SCRIPT_DIR/cpu-temp-wrapper.sh -s"
COMMAND2="$SCRIPT_DIR/gpu-temp-wrapper.sh -s"

OUTPUT_FILE1="$DATA_LOG_DIR/cpu_temp_output.log" # Data logs go to DATA_LOG_DIR
OUTPUT_FILE2="$DATA_LOG_DIR/gpu_temp_output.log" # Data logs go to DATA_LOG_DIR
SCRIPT_LOG="$SERVICE_LOG_DIR/out.log"           # Script's own logs go to SERVICE_LOG_DIR

# --- Functions ---

# Function to log messages.
# Messages are written to SCRIPT_LOG and also echoed to stdout for systemd journal capture.
log_message() {
    local type="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$type] $message" | tee -a "$SCRIPT_LOG"
}

# Function to ensure output directories exist and are writable by the current user.
ensure_output_dirs() {
    # Check SERVICE_LOG_DIR
    if [ ! -d "$SERVICE_LOG_DIR" ]; then
        log_message "ERROR" "Service log directory '$SERVICE_LOG_DIR' not found. It should be created by setup-service-users.sh."
        exit 1
    fi
    if [ ! -w "$SERVICE_LOG_DIR" ]; then
        log_message "ERROR" "Service log directory '$SERVICE_LOG_DIR' is not writable by the current user ($(whoami)). Please check permissions."
        exit 1
    fi
    log_message "INFO" "Service log directory '$SERVICE_LOG_DIR' is accessible."

    # Check DATA_LOG_DIR
    if [ ! -d "$DATA_LOG_DIR" ]; then
        log_message "ERROR" "Data log directory '$DATA_LOG_DIR' not found. It should be created by setup-service-users.sh."
        exit 1
    fi
    if [ ! -w "$DATA_LOG_DIR" ]; then
        log_message "ERROR" "Data log directory '$DATA_LOG_DIR' is not writable by the current user ($(whoami)). Please check permissions."
        exit 1
    fi
    log_message "INFO" "Data log directory '$DATA_LOG_DIR' is accessible."
}

# --- Main Script Logic ---

# Ensure all output directories are ready before starting the main loop.
ensure_output_dirs

log_message "INFO" "Starting monitoring script (PID: $$)."
log_message "INFO" "Service logs: $SERVICE_LOG_DIR"
log_message "INFO" "Data logs: $DATA_LOG_DIR" # Confirm which DATA_LOG_DIR was chosen
log_message "INFO" "Loop interval: $INTERVAL_MINUTES minutes ($SLEEP_SECONDS seconds)" # Updated log message
log_message "INFO" "Command 1: '$COMMAND1' -> Appending to $OUTPUT_FILE1"
log_message "INFO" "Command 2: '$COMMAND2' -> Appending to $OUTPUT_FILE2"

while true; do
    log_message "INFO" "Executing commands..."

    # Execute Command 1.
    # Redirect stderr (wrapper's debug/info) to SCRIPT_LOG.
    # Pipe stdout (actual temperature data) to sed and then to OUTPUT_FILE1.
    log_message "INFO" "Executing '$COMMAND1'..."
    if ! eval "$COMMAND1" 2>>"$SCRIPT_LOG" | sed "s/^/[$(date '+%Y-%m-%d %H:%M:%S')]| /" >> "$OUTPUT_FILE1"; then
        log_message "WARN" "Command 1 ('$COMMAND1') failed. Check $OUTPUT_FILE1 and $SCRIPT_LOG for details."
    else
        log_message "INFO" "Command 1 output appended to $OUTPUT_FILE1."
    fi

    # Execute Command 2.
    # Redirect stderr (wrapper's debug/info) to SCRIPT_LOG.
    # Pipe stdout (actual temperature data) to sed and then to OUTPUT_FILE2.
    log_message "INFO" "Executing '$COMMAND2'..."
    if ! eval "$COMMAND2" 2>>"$SCRIPT_LOG" | sed "s/^/[$(date '+%Y-%m-%d %H:%M:%S')]| /" >> "$OUTPUT_FILE2"; then
        log_message "WARN" "Command 2 ('$COMMAND2') failed. Check $OUTPUT_FILE2 and $SCRIPT_LOG for details."
    else
        log_message "INFO" "Command 2 output appended to $OUTPUT_FILE2."
    fi

    log_message "INFO" "Commands executed. Waiting for $SLEEP_SECONDS seconds..."
    # Pause the script for the configured duration before the next loop iteration.
    sleep "$SLEEP_SECONDS"
done

# This part will technically never be reached in a continuous loop unless the script is terminated.
log_message "INFO" "Script terminated unexpectedly."
exit 0
