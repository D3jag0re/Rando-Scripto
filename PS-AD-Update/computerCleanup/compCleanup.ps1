# Find all domain joined computers that have not been logged into in 6+ months and move them to a disabled folder 

# List ALL computers and their last login time, export to CSV 
# Get-ADComputer -filter * -Properties "LastLogonDate" | select DNSHostName, LastLogonDate | Export-csv -Path ./zzzlog.csv

# Set the target OU where the inactive devices will be moved
$TargetOU = "OU=InactiveComputers,DC=yourdomain,DC=com"

# Path to log file
$LogFile = ".\InactiveDevicesLog.txt"

# Get the date six months ago
$SixMonthsAgo = (Get-Date).AddMonths(-6)

# Get all computers and filter by last logon date
Get-ADComputer -Filter * -Properties "LastLogonDate" | ForEach-Object {
    $LastLogonDate = $_.LastLogonDate
    $ComputerName = $_.DNSHostName

    # Check if the computer has not been logged into in the last 6 months
    if ($LastLogonDate -lt $SixMonthsAgo -or !$LastLogonDate) {
        try {
            # Move the computer to the target OU
            Move-ADObject -Identity $_.DistinguishedName -TargetPath $TargetOU

            # Log the moved computer
            $LogEntry = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Moved: $ComputerName which was last accessed on $LastLogonDate"
            Add-Content -Path $LogFile -Value $LogEntry

            Write-Host "Moved $ComputerName to $TargetOU and logged the action." -ForegroundColor Green
        }
        catch {
            # Log any errors
            $ErrorEntry = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Failed to move: $ComputerName. Error: $_"
            Add-Content -Path $LogFile -Value $ErrorEntry

            Write-Host "Failed to move $ComputerName. Check log for details." -ForegroundColor Red
        }
    }
}
