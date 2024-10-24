# This just simply checks a specified OU and logs which users do not have an EmployeeID assigned

param (
    [string]$OU = "OU=YourOU,DC=domain,DC=com",  # Replace with the distinguished name of your target OU
    [string]$logFilePath = "C:\path\to\your\logfile.txt"  # Path for your log file
)

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Get all users from the specified OU
$users = Get-ADUser -Filter * -SearchBase $OU -Properties employeeID, SamAccountName

# Loop through each user and check if the employeeID is empty or null
foreach ($user in $users) {
    if (-not $user.employeeID) {
        # Log users without employeeID
        $message = "User $($user.SamAccountName) does not have an employeeID."
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    }
}

# Log the script end time with a timestamp
$endTime = "Script ended at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $endTime
