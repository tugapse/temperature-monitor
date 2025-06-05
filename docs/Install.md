# Installation Guide: Temperature Monitoring Service

This guide will walk you through the process of installing the temperature monitoring service on your Arch Linux system. Please follow the steps carefully.

## Installation Workflow (Recommended Method)

Follow these steps to set up the service. It is highly recommended to start from a clean state (the `reset.sh` script handles this for you).

1.  **Clone the project:**
    *   Open your terminal and navigate to your home directory or any other convenient location where you want to store the project.
    *   Clone the `temperature-monitor` repository from GitHub into a directory named `TEMP-MONITOR`.

    ```bash
    cd ~
    git clone https://github.com/tugapse/temperature-monitor.git TEMP-MONITOR
    cd TEMP-MONITOR/
    ```

    This will create the `TEMP-MONITOR` directory and download all project files into it, including the `docs/` folder.

2.  **Make all local scripts executable:**
    *   Make sure all your Bash scripts have executable permissions.

    ```bash
    chmod +x *.sh
    ```

    (The `temperature-monitor.service` file does not need to be executable.)

3.  **Perform a Full Reset and Installation using `reset.sh`:**
    *   The `reset.sh` script automates the entire process of cleaning up any previous state, configuring the user/groups/directories, cloning repositories, installing Python dependencies, and finally installing and starting the systemd service. This is the most robust and recommended way to install the service.
    *   Execute this script using `sudo` from your `TEMP-MONITOR/` directory:

    ```bash
    sudo ./reset.sh
    ```

    *   Follow the interactive prompts provided by the `reset.sh` script. It will explain each step (removing old components, setting up new ones, installing the service) and ask for your confirmation before proceeding.

## Why `reset.sh` is important:

This script simplifies the entire setup. It ensures that the system is properly configured for the service to run securely and reliably by handling the creation of the dedicated user, the system-wide log directories, the cloning of Python repositories, and the installation of their virtual environments and dependencies. The cloning and initial setup steps are executed as the `sudo` user (who typically has network access and Git access without credential credentials).

## What Happens During Installation (`sudo ./reset.sh`)

When you run the `reset.sh` script, it orchestrates the following actions (with user confirmation at each major step):

1.  **Removal of Old Service (if any):** Stops, disables, and deletes the `temperature-monitor.service` file from `/etc/systemd/system/`. It also removes `temperature-monitor-runner.sh`, `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, and `python_script_runner.sh` from `/usr/local/bin/`.
2.  **Cleanup of System Resources:** Deletes the service log directory (`/var/log/temperature-monitor`), the data log directory (`/var/lib/temperature-monitor/data`), and the tools directory (`/usr/local/bin/tools`). It also removes the `temperature_monitor_user` system user and `temperature_monitor_group`.
3.  **System Configuration:**
    *   Creates the `temperature_monitor_user` system user and `temperature_monitor_group`.
    *   Creates the service log directory (`/var/log/temperature-monitor/`) and the data log directory (`/var/lib/temperature-monitor/data/`).
    *   Creates the tools directory (`/usr/local/bin/tools/`).
    *   Clones your `cpu-temp` and `gpu-temp` repositories from GitHub (as defined in `setup-service-users.sh`) into `/usr/local/bin/tools/`.
    *   Creates Python virtual environments within each cloned repository and installs the dependencies listed in their respective `requirements.txt` files.
    *   Sets appropriate ownership and permissions for all these directories and files to allow `temperature_monitor_user` to access and write to them.
4.  **Local Script Permissions:** Makes sure all local project scripts (.sh files) have executable permissions, which is a safeguard before they are copied.
5.  **Service Installation and Start:**
    *   Copies `run.sh` (renamed to `temperature-monitor-runner.sh`), `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, and `python_script_runner.sh` to `/usr/local/bin/`.
    *   Sets executable permissions for these copied scripts.
    *   Copies `temperature-monitor.service` to `/etc/systemd/system/`.
    *   Patches the `temperature-monitor.service` file to include the `Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=10` line, setting the default monitoring interval.
    *   Reloads the systemd daemon, enables the service to start on boot, and starts it immediately.

Once the installation is complete, proceed to the Usage Guide to learn how to check and interact with your running service.

## Prerequisites

Before starting the installation, make sure you have the following on your system:

*   **System Tools:** `Git` and `Python3`
    *   These tools must be installed on your Arch Linux system before you run the setup scripts. They are essential for the `setup-service-users.sh` script (which is called by `reset.sh`) to be able to:
        *   `Git`: Clone the `cpu-temp` and `gpu-temp` Python project repositories from GitHub.
        *   `Python 3`: Create isolated Python virtual environments (`python3 -m venv`) and install necessary project dependencies (like `psutil` or `pynvml`) into these environments. On some distributions, this might require a separate package such as `python3-venv`.
*   **Your `cpu-temp` and `gpu-temp` Python Repositories on GitHub:**
    *   The setup process (specifically via `reset.sh` and internally `setup-service-users.sh`) is designed to automatically clone these Python project repositories (from the `tugapse` organization, as configured in `setup-service-users.sh`) to a system-wide tools directory (`/usr/local/bin/tools/`).
    *   Crucially, make sure each of these repositories on GitHub has a `requirements.txt` file at its root. This file must list all necessary Python dependencies for its respective `main.py` script (e.g., `psutil` for CPU, `pynvml` for GPU). The `setup-service-users.sh` script will read this file and automatically install these dependencies into the virtual environment during the setup process.

## Permissions for the `temperature_monitor_user`

The systemd service will run under a dedicated, unprivileged system user named `temperature_monitor_user` for security reasons. This user needs specific permissions to function correctly:

*   **Network Access:** While initial cloning is done by the `sudo` user during setup, `temperature_monitor_user` does not typically need direct network access itself for basic operation.
*   **Execute Python scripts:** `temperature_monitor_user` needs read and execute permissions for the Python interpreter (usually `/usr/bin/python3`), for the cloned `main.py` files, and for any directories leading to them (specifically `/usr/local/bin/tools/`). The `setup-service-users.sh` script attempts to set these permissions automatically.
*   **Virtual Environment Access:** `temperature_monitor_user` needs read and execute permissions for the virtual environment directories and their contents (e.g., `.venv/bin/activate`, the Python executable within the venv). The `setup-service-users.sh` script attempts to set these.
*   **Write to Log Directories:** The `setup-service-users.sh` script will create and set ownership/permissions for the system-wide log directories (`/var/log/temperature-monitor` and `/var/lib/temperature-monitor/data/`) to allow `temperature_monitor_user` to write to them.

## How to ensure Python script permissions (Crucial Step if problems occur!)

While `setup-service-users.sh` attempts to set all necessary permissions, if you encounter "Permission denied" errors in the service logs, you might need to:

*   Manually verify the permissions of the cloned Python project directories and files in `/usr/local/bin/tools/`.
*   If your Python scripts require access to specific hardware devices (e.g., `/dev/dri/renderD128` for GPUs), you might need to manually adjust the permissions of those resources or add the `temperature_monitor_user` to the appropriate group (e.g., `video` or `render`) using `sudo usermod -aG video,render temperature_monitor_user`.

To test if `temperature_monitor_user` can actually run your wrapper scripts after a full reset and before expecting the service to work:

```bash
sudo -u temperature_monitor_user /usr/local/bin/cpu-temp-wrapper.sh -s
sudo -u temperature_monitor_user /usr/local/bin/gpu-temp-wrapper.sh -s
```

These commands should run without errors and ideally print temperature readings. If they fail, fix the permissions or accesses before proceeding.