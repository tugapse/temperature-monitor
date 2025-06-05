#!/bin/bash
# Wrapper script for the gpu-temp Python project.
# This script sources common logic to activate a virtual environment and execute main.py.

# Define the unique repository name for this wrapper
REPO_NAME="gpu-temp"

# Source the common Python script runner logic
# The path is where temperature_monitor_service_manager.sh will copy it.
source "/usr/local/bin/python_script_runner.sh"

# Call the function from the sourced script to run the Python project.
# Pass all arguments received by this wrapper script.
run_python_project "$@"
exit $? # Exit with the exit code of the called function
