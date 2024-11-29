# Dummt Systemd Service

This is based off the DevOps Roadmap Project [Log Archive Tool](https://roadmap.sh/projects/log-archive-tool)

Create a long-running systemd service that logs to a file. 

This is number 9 of [21 DevOps Projects](https://roadmap.sh/devops/projects) as per roadmap.sh

## Description From Site 

The goal of this project is to get familiar with systemd; creating and enabling a service, checking the status, keeping an eye on the logs, starting and stopping the service, etc.

### Requirements

Create a script called dummy.sh that keeps running forever and writes a message to the log file every 10 seconds simulating an application running in the background. 

Example:
```
#!/bin/bash

while true; do
  echo "Dummy service is running..." >> /var/log/dummy-service.log
  sleep 10
done
```

Create a systemd service dummy.service that should start the app automatically on boot and keep it running in the background. If the service fails for any reason, it should automatically restart.

You should be able to start, stop, enable, disable, check the status of the service, and check the logs i.e. following commands should be available for the service:

```
# Interacting with the service
sudo systemctl start dummy
sudo systemctl stop dummy
sudo systemctl enable dummy
sudo systemctl disable dummy
sudo systemctl status dummy
```

```
# Check the logs
sudo journalctl -u dummy -f
```

After completing this project, you will have a good understanding of systemd, creating custom services, managing existing services, debugging issues, and more.

### Notes 

Used [THIS](https://linuxhandbook.com/create-systemd-services/) for reference in building the service. Setting service for root user. 

Steps: 

- Note location of dummy.sh and modify dummy.service to reflect location if needed 
- Move dummy.service to /etc/systemd/system/
- Reload systemd service (sudo systemctl daemon-reload)

Troubleshooting: 

- At first service was failing because I had a user set under 'Service'
- Also made .sh executable (chmod +x <path>)
- Then got permission denied for the log file write. Had to restart service. 

### Improvements 

- Change script to write to syslog. This should avoid any permission issues as well as make log management easier.
- can check logs with 'sudo journalctl -t dummy-service' 