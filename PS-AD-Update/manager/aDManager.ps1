# This script will parse a csv and update a users Manager attribute 
# This will key off of employeeID

# Import the Active Directory module
Import-Module ActiveDirectory

# Path to your CSV file
$csvFilePath = "C:\path\to\your\file.csv"
$logFilePath = "C:\path\to\log.txt"

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV
$users = Import-Csv -Path $csvFilePath

# Loop through each row in the CSV
foreach ($user in $users) {
    # Extract necessary values from the CSV row
    $fileNumber = $user."File Number"
    $reportsToFirstName = $user."Reports To Legal First Name"
    $reportsToLastName = $user."Reports To Legal Last Name"

    # Search for the AD user with the matching employeeID
    $adUser = Get-ADUser -Filter { employeeID -eq $fileNumber } -Properties Manager

    if ($adUser) {
        # Find the AD user object for the manager
        $manager = Get-ADUser -Filter { GivenName -eq $reportsToFirstName -and Surname -eq $reportsToLastName }

        if ($manager) {
            # Update the Manager field in AD for the user
            Set-ADUser -Identity $adUser -Manager $manager.DistinguishedName
            $message = "Updated manager for $($adUser.SamAccountName) to $($manager.SamAccountName) $($manager.DistinguishedName)"
            Write-Host $message
            Add-Content -Path $logFilePath -Value $message
        } else {
            $message = "Manager not found for $reportsToFirstName $reportsToLastName"
            Write-Host $message
            Add-Content -Path $logFilePath -Value $message
        }
    } else {
        $message = "User with employeeID $fileNumber not found"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    }
}
