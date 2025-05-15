# This script queries AD to return the last 20 users created and saves the info to a logfile. 


# Import the Active Directory module
Import-Module ActiveDirectory

# Define output path
$logPath = "C:\Logs\Last20CreatedUsers.txt"

# Ensure the Logs folder exists
New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null

# Get the last 20 created users and export to log
Get-ADUser -Filter * -Properties Name, EmailAddress, whenCreated |
    Sort-Object whenCreated -Descending |
    Select-Object -First 20 -Property Name, EmailAddress, whenCreated |
    Format-Table Name, EmailAddress, whenCreated -AutoSize |
    Out-String | Set-Content -Path $logPath