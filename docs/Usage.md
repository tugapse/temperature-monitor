## Usage Guide: Temperature Monitoring Service

This guide provides instructions on how to check if your service is running, view its logs, and understand how to customize its behavior.

### Service Status Verification

After installation, the first step is to confirm that your `temperature-monitor.service` is running correctly.

```bash
sudo systemctl status temperature-monitor.service
```

You should see `active (running)` in the output. If it shows `failed` or `inactive`, refer to the Troubleshooting Guide.

### Viewing Logs

The service generates logs in two primary locations:

#### Service Operational Logs (Systemd Journal & `out.log`)

These logs capture the internal messages from the `temperature-monitor-runner.sh` script (e.g., "Starting monitoring script...", "Executing commands...", warnings about failures).

*   **From Systemd Journal (recommended for real-time monitoring and filtering):**

    ```bash
    sudo journalctl -u temperature-monitor.service -f
    ```

    The `-u` flag specifies the unit (service) to view. The `-f` (follow) flag continuously displays new log entries as they are generated. Press Ctrl+C to exit the follow mode.

    You can add `--since "1 hour ago"` or `--since "yesterday"` to view logs from a specific timeframe.

    (sudo is generally required for `journalctl` to view system service logs, depending on your system's `journalctl` permissions.)

*   **From the `out.log` file:**

    ```bash
    sudo tail -f /var/log/temperature-monitor/out.log
    ```

    (sudo is required for this file as it is owned by `temperature_monitor_user` with restricted group permissions.)

#### Temperature Data Logs (`cpu_temp_output.log` & `gpu_temp_output.log`)

These logs contain the actual temperature readings collected by your `cpu-temp` and `gpu-temp` scripts. Each entry is timestamped.

*   **View CPU temperature data:**

    ```bash
    tail -f /var/lib/temperature-monitor/data/cpu_temp_output.log
    ```

    (No sudo required after setup, as this directory and its contents are made world-readable.)

*   **View GPU temperature data:**

    ```bash
    tail -f /var/lib/temperature-monitor/data/gpu_temp_output.log
    ```

    (No sudo required after setup, as this directory and its contents are made world-readable.)

**Example data log entry format:** `[YYYY-MM-DD HH:MM:SS]| <temperature_reading>`

### Customizing the Service

The behavior of the temperature monitoring service can be customized by editing the source files in your `~/TEMP-MONITOR/` directory (or wherever you cloned the project).

**Key Files for Customization:**

*   `run.sh`:
    *   `DEFAULT_INTERVAL_MINUTES`: Change the default loop interval in minutes if the `TEMPERATURE_MONITOR_INTERVAL_MINUTES` environment variable is not explicitly set (this is the fallback in `run.sh` itself).
    *   `SERVICE_LOG_DIR`: Adjust where the `out.log` file is stored (remember to update `setup-service-users.sh` and `cleanup-setup-users.sh` if you change this).
*   `temperature-monitor.service`:
    *   User/Group: Change the dedicated user/group under which the service runs (remember to also update `setup-service-users.sh`).
    *   `Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=10`: This is the primary variable to change the monitoring interval for the service. Edit this line directly in `/etc/systemd/system/temperature-monitor.service` (or in your local project’s copy before running `reset.sh`). For example, to set it to 5 minutes:  `Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=5`
        *   Remember to reload the systemd daemon (`sudo systemctl daemon-reload`) and restart the service (`sudo systemctl restart temperature-monitor.service`) after making this change.
*   `setup-service-users.sh`:
    *   `PYTHON_REPOS`: This associative array defines the GitHub repository URLs for `cpu-temp` and `gpu-temp`. If you are using your own forks or different Python projects, you must update these URLs in this file.
*   Other Systemd options (e.g., `StartLimitBurst`, `RestartSec`).

**Applying Customizations**

*   **Full Reset:**

    ```bash
    cd ~/TEMP-MONITOR/ # Navigate to your project directory
    sudo ./reset.sh
    ```

*   **Partial Reinstallation:**

    ```bash
    cd ~/TEMP-MONITOR/ # Navigate to your project directory
    sudo ./temperature_monitor_service_manager.sh install
    ```

**Running `run.sh` Manually with a Custom Interval**

If you want to test `run.sh` directly from your terminal and specify the monitoring interval for that particular run (overriding its internal default or the service’s configured value), you can pass it as an environment variable:

```bash
TEMPERATURE_MONITOR_INTERVAL_MINUTES=5 sh ~/TEMP-MONITOR/run.sh
```

This will make `run.sh` use a 5-minute interval for its execution.

Continue to the Troubleshooting Guide if you encounter any issues.
