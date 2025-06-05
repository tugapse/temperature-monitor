## Installation Guide: Temperature Monitoring Service

This guide will walk you through the process of installing the temperature monitoring service on your Arch Linux system. Please follow the steps carefully.

## Installation Workflow (Recommended Method)

Follow these steps to set up the service. It is highly recommended to start from a clean state (the reset.sh script handles this for you).

1.  **Clone the project:**
    *   Open your terminal and navigate to your home directory or any other convenient location.
    *   Clone the temperature-monitor repository from GitHub:

        ```bash
        git clone https://github.com/tugapse/temperature-monitor.git TEMP-MONITOR
        cd TEMP-MONITOR/
        ```

2.  **Make local scripts executable:**

    ```bash
    chmod +x *.sh
    ```

    *(The temperature-monitor.service file does not need to be executable.)*

3.  **Customize temperature-monitor.service (Optional):** If you wish to set a different default monitoring interval, edit the `temperature-monitor.service` file in your `TEMP-MONITOR/` project directory.  Find the line:

    ```
    Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=10
    ```

    Change the `10` to your desired interval in minutes (e.g., `5` for 5 minutes).

4.  **Perform a Full Reset and Installation using reset.sh:**

    Execute this script using `sudo` from your `TEMP-MONITOR/` directory:

    ```bash
    sudo ./reset.sh
    ```

    Follow the interactive prompts provided by the `reset.sh` script.

## Why reset.sh is important:

This script simplifies the entire setup. It ensures that the system is properly configured for the service to run securely and reliably by handling the creation of the dedicated user, the system-wide log directories, the cloning of Python repositories, and the installation of their virtual environments and dependencies.  The cloning and initial setup steps are executed as the `sudo` user.

## What Happens During Installation (sudo ./reset.sh)

The `reset.sh` script orchestrates the following actions:

*   **Removal of Old Service (if any):** Stops, disables, and deletes the `temperature-monitor.service` file. Removes `temperature-monitor-runner.sh`, `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, and `python_script_runner.sh`.
*   **Cleanup of System Resources:** Deletes log and data directories.  Removes the `temperature_monitor_user` system user and `temperature_monitor_group`.
*   **System Configuration:** Creates the `temperature_monitor_user` and `temperature_monitor_group`.  Creates log and tools directories.
*   **Clones Python Projects:** Clones the `cpu-temp` and `gpu-temp` repositories into `/usr/local/bin/tools`. Creates Python virtual environments and installs dependencies.
*   **Sets Ownership and Permissions:** Sets appropriate ownership and permissions for directories and files.
*   **Local Script Permissions:** Makes all local project scripts executable.
*   **Service Installation and Start:** Copies scripts to `/usr/local/bin/`.  Sets executable permissions. Copies `temperature-monitor.service` to `/etc/systemd/system/`. Reloads the systemd daemon, enables the service, and starts it.

## Prerequisites

Before starting the installation, ensure you have the following:

*   **System Tools:** Git and Python 3:

    ```bash
    sudo pacman -S git python python-pip
    ```

*   **External Temperature Sensing Python Projects:** Requires that the external repositories include a `requirements.txt` file.

    *   `https://github.com/tugapse/cpu-temp.git`
    *   `https://github.com/tugapse/gpu-temp.git`

## Customization:

If using your own forks of these projects, or different Python scripts, edit the `PYTHON_REPOS` variable in `setup-service-users.sh`.

## System's Ability to Grant Permissions:

The `temperature_monitor_user` may need permission to access hardware devices. Add the user to relevant system groups (e.g., `video`, `render`) if necessary.