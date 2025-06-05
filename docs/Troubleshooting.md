## Troubleshooting Guide: Temperature Monitoring Service

This guide provides solutions for common issues you might encounter when installing, running, or verifying the temperature monitoring service.

### General Debugging Steps

*   **Check Service Status:** `sudo systemctl status temperature-monitor.service` (Look for active, inactive, active (exited), or failed)
*   **Check Systemd Journal Logs:** `journalctl -u temperature-monitor.service -f` (Real-time output from `log_message` and systemd errors)
*   **Check Specific Log Files:**
    *   Script's own logs: `sudo tail -f /var/log/temperature-monitor/out.log`
    *   CPU temperature data logs: `sudo tail -f /var/lib/temperature-monitor/data/cpu_temp_output.log`
    *   GPU temperature data logs: `sudo tail -f /var/lib/temperature-monitor/data/gpu_temp_output.log`
    *   *Example log entry format:* `[YYYY-MM-DD HH:MM:SS]| <temperature_reading>`

### Common Issues and Solutions

1.  **Service Fails to Start (active (exited) or failed)**

    *   *Probable Cause:* Script syntax error, wrapper script failure (cpu-temp-wrapper.sh or gpu-temp-wrapper.sh), or permission issues.
    *   *Solution:*
        *   Review `journalctl -u temperature-monitor.service -f` immediately.
        *   Check script syntax: `bash -n ~/my_monitor_project/run.sh`
        *   Check executable permissions:
            *   `ls -l /usr/local/bin/temperature-monitor-runner.sh`
            *   `ls -l /usr/local/bin/cpu-temp-wrapper.sh`
            *   `ls -l /usr/local/bin/gpu-temp-wrapper.sh`
            *   `ls -l /usr/local/bin/python_script_runner.sh` (*Expected output includes 'x'*)
        *   Run the script manually: `sudo -u temperature_monitor_user /usr/local/bin/temperature-monitor-runner.sh` (Ctrl+C to stop)

2.  **"Permission denied" Errors in Logs**

    *   *Probable Cause:* `temperature_monitor_user` lacks access to Python scripts (/usr/local/bin/tools/) or cannot write to log directories (/var/log/temperature-monitor, /var/lib/temperature-monitor/data).
    *   *Solution:*
        *   Re-run the full reset script: `sudo ./reset.sh`
        *   Manually verify permissions:
            *   `ls -ld /var/log/temperature-monitor`
            *   `ls -ld /var/lib/temperature-monitor/data`
            *   `ls -ld /usr/local/bin/tools` (*Ownership: `temperature_monitor_user:temperature_monitor_group`, mode: `770` for directories; read/execute permissions for group within `/usr/local/bin/tools`*)
        *   Test write capability:
            *   `sudo -u temperature_monitor_user touch /var/log/temperature-monitor/test_write.log`
            *   `sudo -u temperature_monitor_user touch /var/lib/temperature-monitor/data/test_write_2.log`

3.  **`ModuleNotFoundError: No module named '...'` Errors**

    *   *Probable Cause:* Missing Python dependency (e.g., `psutil`) not in virtual environment; failed `pip` installation.
    *   *Solution:*
        *   Check GitHub repositories: (`https://github.com/tugapse/cpu-temp`, `https://github.com/tugapse/gpu-temp`) - Ensure `requirements.txt` lists all dependencies. Commit and push changes.
        *   Re-run the full reset: `sudo ./reset.sh`
        *   Review setup logs: Observe output of `sudo ./reset.sh` for cloning/`pip` errors.

4.  **`Warning: Unknown key 'StartLimitIntervalSec' in journalctl`**

    *   *Cause:* Systemd version incompatibility.
    *   *Solution:* No action needed.  Remove/comment out lines in `/etc/systemd/system/temperature-monitor.service` containing `StartLimitIntervalSec` and `StartLimitBurst`, then: `sudo systemctl daemon-reload`, `sudo systemctl restart temperature-monitor.service`