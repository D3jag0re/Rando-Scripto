# SH Unifi AP Reboot

- This script runs as a cron job to reboot Unifi APs.  It runs on the same server as the unifi controller. 
- This assumes a specific naming convention of 'wap##'
- Each AP is rebooted 2.5min apart.
- Using u/n and pass in this but should ideally use keys
- To run every day in crontab : 0 1 * * * /path/to/script.sh