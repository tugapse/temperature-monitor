## Cleanup Guide: Temperature Monitoring Service

This guide provides instructions on how to completely remove the temperature monitoring service, its associated scripts, logs, and dedicated system user/group from your Arch Linux system.

## Full Removal Workflow

Follow these steps to completely remove all components of the service.

### Remove the service and installed scripts:

```bash
sudo ./temperature_monitor_service_manager.sh remove
```

*Why this step is important:* It ensures the service is no longer running or configured to auto-start, and removes the main executable components from system paths.

### Remove the log and tools directories (Optional, but recommended for a clean slate):

```bash
sudo rm -rf /var/log/temperature-monitor
sudo rm -rf /var/lib/temperature-monitor/data
sudo rm -rf /usr/local/bin/tools
```

*WARNING: `rm -rf` deletes files and directories permanently without prompting. Ensure these are the directories you intend to delete.*

### Remove the dedicated system user and group (Optional, but recommended for a clean slate):

```bash
sudo userdel temperature_monitor_user
sudo groupdel temperature_monitor_group
```

*Why this step is important:* To remove system clutter if you no longer need the dedicated user account.

### Remove your local project directory (Optional):

```bash
rm -rf ~/my_monitor_project
```

*Why this step is important:* To clean up your development environment.

By following these steps, your system will be clean of the temperature monitoring service and its related files.