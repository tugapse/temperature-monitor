# Troubleshooting Guide: Temperature Monitoring Service

This guide provides solutions for common issues you might encounter when installing, running, or verifying the temperature monitoring service.

## General Debugging Steps

*   **Check Service Status:** `sudo systemctl status temperature-monitor.service` (Look for active, inactive, active (exited), or failed.)
*   **Check Systemd Journal Logs:** `sudo journalctl -u temperature-monitor.service -f` (Use `-f` to follow, Ctrl+C to exit. Add `--since "1 hour ago"` or `--since "yesterday"` to view logs from a specific timeframe.)
*   **Check Specific Log Files:**
    *   Service's own operational logs (out.log): `sudo tail -f /var/log/temperature-monitor/out.log`
    *   CPU temperature data logs (cpu\_temp\_output.log): `tail -f /var/lib/temperature-monitor/data/cpu_temp_output.log`
    *   GPU temperature data logs (gpu\_temp\_output.log): `tail -f /var/lib/temperature-monitor/data/gpu_temp_output.log`

## Common Issues and Solutions

### 1. Service Fails to Start (active (exited) or failed)

*   **Probable Cause:** Script syntax error, failure in wrapper scripts (cpu-temp-wrapper.sh or gpu-temp-wrapper.sh), or severe permission issues.
*   **Solution:**
    *   Review `sudo journalctl -u temperature-monitor.service -f`
    *   Check script syntax: `bash -n ~/TEMP-MONITOR/run.sh`
    *   Check executable permissions:
        *   `ls -l /usr/local/bin/temperature-monitor-runner.sh`
        *   `ls -l /usr/local/bin/cpu-temp-wrapper.sh`
        *   `ls -l /usr/local/bin/gpu-temp-wrapper.sh`
        *   `ls -l /usr/local/bin/python_script_runner.sh`
    *   Run script manually as service user: `sudo -u temperature_monitor_user /usr/local/bin/temperature-monitor-runner.sh`

### 2. "Permission denied" Errors in Logs

*   **Probable Cause:**
    *   `temperature_monitor_user` cannot read/execute Python scripts in `/usr/local/bin/tools/`.
    *   `temperature_monitor_user` cannot write to log directories (`/var/log/temperature-monitor` or `/var/lib/temperature-monitor/data`).
    *   Python scripts require hardware device access (`/dev/dri/renderD128`) that `temperature_monitor_user` lacks.
*   **Solution:**
    *   Re-run `sudo ./reset.sh`
    *   Manually verify permissions:
        *   `ls -ld /var/log/temperature-monitor`
        *   `ls -ld /var/lib/temperature-monitor/data`
        *   `ls -ld /usr/local/bin/tools`
    *   Test write capability as service user:
        *   `sudo -u temperature_monitor_user touch /var/log/temperature-monitor/test_write.log`
        *   `sudo -u temperature_monitor_user touch /var/lib/temperature-monitor/data/test_write_2.log`
    *   For Hardware Access Issues: `sudo usermod -aG video,render temperature_monitor_user`, then `sudo systemctl restart temperature-monitor.service`

### 3. ModuleNotFoundError: No module named '...' Errors

*   **Probable Cause:** Missing Python dependency in `requirements.txt`, or failed pip installation.
*   **Solution:**
    *   Check `requirements.txt` files in CPU and GPU repositories.
    *   Re-run `sudo ./reset.sh`
    *   Review setup logs during dependency installation.

### 4. Warning Unknown key 'StartLimitIntervalSec' in journalctl

*   **Cause:** Systemd version incompatibility.
*   **Solution:** No action needed. (Optionally, edit `/etc/systemd/system/temperature-monitor.service` to remove the lines containing `StartLimitIntervalSec` and `StartLimitBurst`, then run `sudo systemctl daemon-reload` and `sudo systemctl restart temperature-monitor.service`)