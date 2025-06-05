## Cleanup Guide: Temperature Monitoring Service

This guide provides instructions on how to completely remove the temperature monitoring service, its associated scripts, logs, and dedicated system user/group from your Arch Linux system.

### Full Removal Workflow

Follow these steps in order to completely remove all components of the service. You should execute these commands from your project's root directory (e.g., ~/TEMP-MONITOR/).

### Remove the service and installed scripts

This command will stop the `temperature-monitor.service`, disable it from starting on boot, delete its systemd service file from `/etc/systemd/system/`, and remove the installed runner script (`temperature-monitor-runner.sh`), `cpu-temp-wrapper.sh`, `gpu-temp-wrapper.sh`, and `python_script_runner.sh` from `/usr/local/bin/`.

```bash
cd ~/TEMP-MONITOR/ # Navigate to your project directory
sudo ./temperature_monitor_service_manager.sh remove
```

*Why this step is important:* It ensures the service is no longer running or configured to auto-start, and removes the main executable components from system paths.

### Remove the log and tools directories (Optional, but recommended for a clean slate)

This step removes the directories where the service wrote its operational logs, temperature data, and where the Python repositories were cloned.

**WARNING:** `rm -rf` deletes files and directories permanently without prompting.
Ensure these are the directories you intend to delete.

```bash
sudo rm -rf /var/log/temperature-monitor
sudo rm -rf /var/lib/temperature-monitor/data
sudo rm -rf /usr/local/bin/tools
```

### Remove the dedicated system user and group (Optional, but recommended for a clean slate)

This step removes the `temperature_monitor_user` and `temperature_monitor_group` that were created for the service during installation.

```bash
sudo userdel temperature_monitor_user
sudo groupdel temperature_monitor_group
```

*Why this step is important:* To remove system clutter if you no longer need the dedicated user account.

### Remove your local project directory (Optional)

Once everything has been removed from your system, you can delete your local project directory.

```bash
rm -rf ~/TEMP-MONITOR
```

*Why this step is important:* To clean up your development environment.