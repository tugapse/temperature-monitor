# Temperature Monitoring Service for Arch Linux

This project provides a robust and easy-to-manage solution for continuously monitoring your system's CPU and GPU temperatures on Arch Linux. It utilizes a dedicated Bash script (run.sh) to periodically collect temperature data and log it to specific files, operating reliably in the background as a systemd service.

This setup is designed for users who require consistent, automated temperature logging for performance analysis, system health monitoring, or custom alerting.

## What This Program Does

At its core, this service performs the following tasks:

*   **Temperature Collection:** Periodically executes your `cpu-temp` and `gpu-temp` Python projects (automatically cloned and virtual environment managed) to fetch the latest temperature readings.
*   **Intelligent Logging:** Appends these temperature readings, each timestamped, to dedicated log files (`cpu_temp_output.log` and `gpu_temp_output.log`).
*   **Separated Logs:** The operational logs of the service itself (out.log) are stored in a standard system log location (/var/log/temperature-monitor). Your collected temperature data resides in a dedicated system data directory (/var/lib/temperature-monitor/data).
*   **Background Operation:** Runs as a systemd service, ensuring it starts automatically on boot and recovers gracefully from unexpected exits.
*   **Enhanced Security:** The service runs under a dedicated, unprivileged system user (`temperature_monitor_user`) to minimize potential security risks.
*   **Self-Configuration:** The setup scripts handle cloning the Python repositories (`cpu-temp` and `gpu-temp`) from GitHub to a system location (/usr/local/bin/tools), create the necessary Python virtual environments, and install dependencies (requirements.txt).
*   **Configurable Interval:** The monitoring loop interval (how often temperatures are checked) can be easily adjusted via a systemd environment variable.

## Project Structure

Your local project directory should contain the following files:

```
TEMP-MONITOR/
├── docs/                                   # Directory for detailed documentation files
│   ├── Clean.md                            # Detailed cleanup guide
│   ├── Install.md                          # Detailed installation guide
│   ├── Troubleshooting.md                  # Common issues and debugging steps
│   └── Usage.md                            # How to use and monitor the service
├── cpu-temp-wrapper.sh                     # Wrapper script for the cpu-temp Python project
├── gpu-temp-wrapper.sh                     # Wrapper script for the gpu-temp Python project
├── python_script_runner.sh                 # Common logic shared by wrapper scripts
├── README.md                               # This overview file
├── reset.sh                                # Interactive script to perform a full reset and reinstallation
├── run.sh                                  # The main monitoring script (source)
├── setup-service-users.sh                  # Script to set up dedicated user, group, and log/tools directories
├── temperature_monitor_service_manager.sh  # Script to install, update, and remove the service
└── temperature-monitor.service             # Systemd service definition
```

## Getting Started

To install and manage this temperature monitoring service, please refer to the following detailed guides located in the `docs/` directory:

*   Installation Guide: Learn how to set up your system, install the service, and understand the rationale behind each step.
*   Usage Guide: Discover how to interact with the service, view logs, and customize its behavior.
*   Troubleshooting Guide: Find solutions to common issues and debugging tips.
*   Cleanup Guide: Instructions for completely removing the service and all its associated files.