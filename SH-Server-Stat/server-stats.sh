#!/bin/bash 
# Display Server Stats

echo -e 'Current Server Stats:\n' 

## Total CPU Usage ##
echo -e "CPU Usage: $(top -n 1 | grep "Cpu")\n"

## Total Memory Usage ##
echo -e "Memory Usage: $(free -h | grep ^Mem | awk '{printf "Used: %s, Free: %s, of %s Total", $3, $4, $2}')\n" 

## Total Disk Usage ##
echo -e "Total Disk Usage: $(df -h --output=used --total | awk 'END {print $1}') used of $(df -h --output=size --total | awk 'END {print $1}') - $(df -h --output=avail --total | awk 'END {print $1}') Available\n"

## Top 5 Processes by CPU Usage ##
echo -e "Top 5 Processes by CPU Usage:\n $(top -o %CPU -n 1 | head -n 12 | tail -6)\n"

## Top 5 Processes by Memory Usage ##
echo -e "Top 5 Processes by CPU Usage:\n $(top -o %MEM -n 1 | head -n 12 | tail -6)\n"

## OS Version ## 
echo -e "OS Version: $(grep ^PRETTY_NAME= /etc/os-release | cut -d '"' -f 2)\n"

## Uptime ##
uptime=$(uptime -p)
echo -e "System has been $uptime\n"

## Logged In Users ## 
echo -e "Currently Logged in Users are: $(users)\n"

## Failed Login Attempts ## 
echo -e "Failed Login Attempts: $(grep "Failed password" /var/log/auth.log | head -3)\n"











#top -o %MEM
#top -o %CPU
#top -n 1 -b > top-output.txt #saves it to file
#head -n 12 top-output.txt | tail -6 #Pulls top 5 with header

# free for disk space 
# 