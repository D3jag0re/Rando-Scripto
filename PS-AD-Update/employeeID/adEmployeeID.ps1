# This will parse over the specified .csv file and add the employee ID. User match is based on email.

# Define the path to your CSV file and the log file
$csvFilePath = "C:\path\to\file.csv"
$logFilePath = "C:\path\to\log.txt"

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV file
$users = Import-Csv -Path $csvFilePath

# Loop through each user in the CSV
foreach ($user in $users) {
    # Extract email and File Number
    $email = $user."Work Contact: Work Email"
    $fileNumber = $user."File Number"

    # Search for the user in Active Directory by their email (mail attribute)
    $adUser = Get-ADUser -Filter "mail -eq '$email'" -Properties mail, employeeID

    # If the user is found in AD
    if ($adUser) {
        # Update the employeeID attribute with the File Number
        Set-ADUser -Identity $adUser -EmployeeID $fileNumber
   
        # Log and print the success
        $message = "Updated employeeID for $($adUser.SamAccountName) $email with File Number: $fileNumber"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    } else {
        # Log and print the failure (user not found)
        $message = "No matching AD user found for email: $email $fileNumber"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    }
}

# Log the script end time with a timestamp
$endTime = "Script ended at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $endTime


