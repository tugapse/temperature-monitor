## Usage Guide: Temperature Monitoring Service

This guide provides instructions on how to check if your service is running, view its logs, and understand how to customize its behavior.

### Service Status Verification

After installation, the first step is to confirm that your `temperature-monitor.service` is running correctly.

*   **Check overall service status:**

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
    journalctl -u temperature-monitor.service -f
    ```

    *   The `-u` flag specifies the unit (service) to view.
    *   The `-f` (follow) flag continuously displays new log entries as they are generated.
    *   Press Ctrl+C to exit the follow mode.
    *   You can add `--since "1 hour ago"` or `--since "yesterday"` to view logs from a specific timeframe.

*   **From the `out.log` file:**

    ```bash
    sudo tail -f /var/log/temperature-monitor/out.log
    ```

    `tail -f` also "follows" the log file, showing new lines as they are appended.

#### Temperature Data Logs (`cpu_temp_output.log` & `gpu_temp_output.log`)

These logs contain the actual temperature readings collected by your `cpu-temp` and `gpu-temp` scripts. Each entry is timestamped.

*   **View CPU temperature data:**

    ```bash
    sudo tail -f /var/lib/temperature-monitor/data/cpu_temp_output.log
    ```

*   **View GPU temperature data:**

    ```bash
    sudo tail -f /var/lib/temperature-monitor/data/gpu_temp_output.log
    ```

**Example log entry format:** `[YYYY-MM-DD HH:MM:SS]| <temperature_reading>`

### Customizing the Service

The behavior of the temperature monitoring service can be customized by editing the source files in your `~/my_monitor_project/` directory.

#### Key Files for Customization

*   `run.sh`:
    *   `DEFAULT_INTERVAL_MINUTES`: Change the default loop interval in minutes if the `TEMPERATURE_MONITOR_INTERVAL_MINUTES` environment variable is not explicitly set (this is the fallback in `run.sh` itself).
    *   `SERVICE_LOG_DIR`: Adjust where the `out.log` file is stored (remember to update `setup-service-users.sh` and `cleanup-setup-users.sh` if you change this).
*   `temperature-monitor.service`:
    *   User/Group: Change the dedicated user/group under which the service runs (remember to also update `setup-service-users.sh`).
    *   `Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=10`: This is the primary variable to change the monitoring interval for the service. Edit this line directly in `/etc/systemd/system/temperature-monitor.service` if you want to set a different interval for the service. For example, to set it to 5 minutes: `Environment=TEMPERATURE_MONITOR_INTERVAL_MINUTES=5`
        *   Remember to reload the systemd daemon (`sudo systemctl daemon-reload`) and restart the service (`sudo systemctl restart temperature-monitor.service`) after making this change.
    *   Other Systemd options (e.g., `StartLimitBurst`, `RestartSec`).
*   `setup-service-users.sh`:
    *   `PYTHON_REPOS`: This associative array in the script defines the GitHub repository URLs for `cpu-temp` and `gpu-temp`. If your Python project URLs change, update them here.
    *   `MONITOR_USER/MONITOR_GROUP`: Change the dedicated user/group.
    *   `TOOLS_BASE_DIR`: Where Python repositories are cloned.

#### Applying Customizations

After making changes to any of the source files in your project directory (`run.sh`, `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, `python_script_runner.sh`, `temperature-monitor.service`, `setup-service-users.sh`, `temperature_monitor_service_manager.sh`, `reset.sh`), the easiest way to apply them is to run the `reset.sh` script, which automates the full cleanup and reinstallation process.

```bash
cd ~/my_monitor_project/
sudo ./reset.sh
```

Alternatively, for smaller changes (e.g., just `run.sh` or `temperature-monitor.service` updates), you can manually reinstall the service without a full reset:

```bash
cd ~/my_monitor_project/
sudo ./temperature_monitor_service_manager.sh install
```

This will copy updated scripts, patch the service file, reload systemd, and restart the service.

#### Running `run.sh` Manually with a Custom Interval

If you want to test `run.sh` directly from your terminal and specify the monitoring interval for that particular run (overriding its internal default or the service's configured value), you can pass it as an environment variable:

```bash
TEMPERATURE_MONITOR_INTERVAL_MINUTES=5 sh ~/my_monitor_project/run.sh
```

This will make `run.sh` use a 5-minute interval for its execution.

Continue to the Troubleshooting Guide if you encounter any issues.