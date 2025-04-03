#!/bin/bash

USER="your_username"
PASS="your_password"
LOGFILE="reboot_log_$(date +%Y%m%d_%H%M%S).txt"

for i in $(seq -w 21 99); do
    HOST="wap$i"
    echo "Rebooting $HOST..."

    sshpass -p "$PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@$HOST" "reboot" \
        && echo "$HOST rebooted successfully" >> "$LOGFILE" \
        || echo "$HOST failed to reboot or is unreachable" >> "$LOGFILE"

    sleep 180
done

echo "Reboot attempt finished. See $LOGFILE for details."
