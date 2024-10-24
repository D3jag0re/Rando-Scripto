# This will parse over the specified .csv file and add the employee ID. User match is based on email.
# This dryRun version will make no actual changes to AD but will log. i.e. Set-ADUser command has been removed.

# Define the path to your CSV file and the log file
$csvFilePath = "C:\path\to\file.csv"
$logFilePath = "C:\path\to\logfile.txt"

# Log the script start time with a timestamp
$startTime = "Dry Run - Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV file
$users = Import-Csv -Path $csvFilePath

# Loop through each user in the CSV
foreach ($user in $users) {
    # Extract email and File Number
    $email = $user."Work Contact: Work Email"
    $fileNumber = $user."File Number"

    # Search for the user in Active Directory by their email (mail attribute)
    $adUser = Get-ADUser -Filter {mail -eq $email} -Properties mail, employeeID

    # If the user is found in AD
    if ($adUser) {
        # Dry run - simulate what would happen
        $message = "Dry Run: Would update employeeID for $($adUser.SamAccountName) with File Number: $fileNumber"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
        
        # Comment out the actual update to avoid changes in AD
        # Set-ADUser -Identity $adUser -EmployeeID $fileNumber
    } else {
        # Log and print the failure (user not found)
        $message = "Dry Run: No matching AD user found for email: $email"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    }
}

# Log the script end time with a timestamp
$endTime = "Dry Run - Script ended at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $endTime
