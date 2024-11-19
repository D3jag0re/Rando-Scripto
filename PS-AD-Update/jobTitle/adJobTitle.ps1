# This script will parse a csv and update a users Job Title 
# This will key off of employeeID

# Import the Active Directory module
Import-Module ActiveDirectory

# Path to your CSV file
$csvFilePath = "C:\path\to\your\file.csv"
$logFilePath = "C:\path\to\log.txt"

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV file
$users = Import-Csv -Path $csvFilePath

# Loop through each user in the CSV
foreach ($user in $users) {
    # Extract email and File Number
    # Extract necessary values from the CSV row
    $fileNumber = $user."File Number"
    $jobTitle = $user."Job Title Description"

    # Search for the user in Active Directory by their email (mail attribute)
    $adUser = Get-ADUser -Filter { employeeID -eq $fileNumber } -Properties Title

    # If the user is found in AD
    if ($adUser) {
        # Update the employeeID attribute with the File Number
        Set-ADUser -Identity $adUser -Title $jobTitle
   
        # Log and print the success
        $message = "Updated Job Title for $($adUser.SamAccountName) $email with title: $jobTitle"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    } else {
        # Log and print the failure (user not found)
        $message = "No matching AD user found for EmployeeID: $email $fileNumber"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    }
}

# Log the script end time with a timestamp
$endTime = "Script ended at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $endTime