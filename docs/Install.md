## Installation Guide: Temperature Monitoring Service

This guide will walk you through the process of installing the temperature monitoring service on your Arch Linux system. Please follow the steps carefully.

### Prerequisites

Before starting the installation, ensure the following are in place:

*   **Git and Python3:** These are essential for the setup script to clone the Python repositories and create the virtual environments.
    *   Git: For cloning the temperature repositories.
    *   Python 3: With the ability to create virtual environments (python3 -m venv). On some distributions, this might require a separate package like python3-venv.
*   **Your cpu-temp and gpu-temp Python Repositories on GitHub:** The service will clone these GitHub repositories (from the tugapse organization) to `/usr/local/bin/tools/`.
    *   Ensure each repository has a `requirements.txt` file at its root. This file must list all necessary Python dependencies for your `main.py` script (e.g., `psutil` for CPU, `pynvml` for GPU). The setup script will automatically install these dependencies.
*   **Permissions for the `temperature_monitor_user`:** The systemd service will run under a dedicated, unprivileged system user named `temperature_monitor_user` for security reasons. This user needs specific permissions to function correctly:
    *   Network Access: For cloning repositories (though cloning is done by the sudo user during setup).
    *   Execute Python scripts: `temperature_monitor_user` needs read and execute permissions for the Python interpreter (usually `/usr/bin/python3`), for the cloned `main.py` files, and for any directories leading to them (specifically `/usr/local/bin/tools/`).
    *   Virtual Environment Access: `temperature_monitor_user` needs read and execute permissions for the virtual environment directories and their contents (e.g., `.venv/bin/activate`, the Python executable within the venv).
    *   Write to Log Directories: The `setup-service-users.sh` script will create and set ownership/permissions for the log directories (`/var/log/temperature-monitor` and `/var/lib/temperature-monitor/data/`) to allow `temperature_monitor_user` to write to them.

### How to ensure Python script permissions (Crucial Step!)

The `setup-service-users.sh` script will recursively set ownership and permissions for the cloned repositories under `/usr/local/bin/tools/`. However, if your original Python scripts (`main.py`) or their dependencies (outside of the cloned repositories) need to access any specific user-owned files or hardware (e.g., `/dev/dri/renderD128` for GPUs), you might need to manually adjust the permissions of those resources or add the `temperature_monitor_user` to the appropriate group (e.g., `video` or `render`).

To test if `temperature_monitor_user` can actually run your wrapper scripts before installing the service:

```bash
sudo -u temperature_monitor_user /usr/local/bin/cpu-temp-wrapper.sh -s
sudo -u temperature_monitor_user /usr/local/bin/gpu-temp-wrapper.sh -s
```

These commands should run without "Permission denied" or "command not found" errors and ideally print temperature readings. If they fail, fix the permissions or accesses before proceeding.

### Installation Workflow

Follow these steps to set up the service. It is highly recommended to start from a clean state (see Cleanup Guide if you had previous installations).

1.  **Place all project files in a dedicated directory:**

    ```bash
    mkdir -p ~/my_monitor_project
    cd ~/my_monitor_project
    ```

    *Place all files here: `run.sh`, `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, `python_script_runner.sh`, `temperature-monitor.service`, `setup-service-users.sh`, `temperature_monitor_service_manager.sh`, `reset.sh`, and the `docs/` directory.*
2.  **Make all local scripts executable:**

    ```bash
    chmod +x *.sh
    ```

    *(The `temperature-monitor.service` file does not need to be executable.)*
3.  **Perform a Full Reset and Installation:**

    The `reset.sh` script automates the entire process of cleaning up any previous state, configuring the user/groups/directories, cloning repositories, installing Python dependencies, and finally installing and starting the systemd service.

    ```bash
    sudo ./reset.sh
    ```

    Follow the prompts provided by the `reset.sh` script. It will explain each step (removing old components, setting up new ones, installing the service) and ask for your confirmation.

### Why this step is important

This script simplifies the entire setup. It ensures that the system is properly configured for the service to run securely and reliably. The cloning process is executed as the sudo user (who typically has network access and Git access without credential issues).

### What Happens During Installation (`sudo ./reset.sh`)

When you run the `reset.sh` script, it orchestrates the following actions (with user confirmation at each major step):

*   **Removal of Old Service (if any):** Stops, disables, and deletes the `temperature-monitor.service` file from `/etc/systemd/system/`. It also removes `temperature-monitor-runner.sh`, `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, and `python_script_runner.sh` from `/usr/local/bin/`.
*   **Cleanup of System Resources:** Deletes the service log directory (`/var/log/temperature-monitor`), the data log directory (`/var/lib/temperature-monitor/data/`), and the tools directory (`/usr/local/bin/tools/`). It also removes the `temperature_monitor_user` system user and `temperature_monitor_group`.
*   **System Configuration:**
    *   Creates the `temperature_monitor_user` system user and `temperature_monitor_group`.
    *   Creates the service log directory (`/var/log/temperature-monitor/`) and the data log directory (`/var/lib/temperature-monitor/data/`).
    *   Creates the tools directory (`/usr/local/bin/tools/`).
    *   Clones your `cpu-temp` and `gpu-temp` repositories from GitHub into `/usr/local/bin/tools/`.
    *   Creates Python virtual environments within each cloned repository and installs the dependencies listed in their respective `requirements.txt` files.
    *   Sets appropriate ownership and permissions for all these directories and files to allow `temperature_monitor_user` to access and write to them.
*   **Local Script Permissions:** Ensures all local project scripts (.sh files) have executable permissions.
*   **Service Installation and Start:**
    *   Copies `run.sh` (renamed to `temperature-monitor-runner.sh`), `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, and `python_script_runner.sh` to `/usr/local/bin/`.
    *   Sets executable permissions for these copied scripts.
    *   Copies `temperature-monitor.service` to `/etc/systemd/system/`.
    *   Patches the `temperature-monitor.service` file to include the `Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=10` line, setting the default monitoring interval.
    *   Reloads the systemd daemon, enables the service to start on boot, and starts it immediately.

Once the installation is complete, proceed to the Usage Guide to learn how to check and interact with your running service.