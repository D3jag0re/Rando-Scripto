# This will extract the time format value from a csv and update the msDS-cloudExtensionAttribute1 attribute in AD 
# This assumes it is already in the correct time format "yyyyMMddHHmmss.fZ"
# This is the time format needed for Entra's "EmployeeHireDate" in order to utilize onboarding workflows 

# Comment out "Set-ADUser" in order for a dry run 

# Import the Active Directory module (if needed)
Import-Module ActiveDirectory

# Path to your CSV file
$csvPath = "C:\path\to\your\file.csv"
$logFilePath = "C:\path\to\startDatelog.txt"

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV file
$users = Import-Csv -Path $csvPath

foreach ($user in $users) {
    # Get the File Number and Converted Date from the CSV row
    $fileNumber = $user."File Number"
    $convertedDate = $user."convertedDate"

    # Search for the user in AD by employeeID
    $adUser = Get-ADUser -Filter {employeeID -eq $fileNumber} -Properties msDS-cloudExtensionAttribute1

    if ($adUser) {
        # Update the msDS-cloudExtensionAttribute1 with the convertedDate value
        Set-ADUser -Identity $adUser -Replace @{ "msDS-cloudExtensionAttribute1" = $convertedDate }
        $message = "Updated msDS-cloudExtensionAttribute1 for $($adUser.Name) with converted date: $convertedDate"
        Write-Output $message
        Add-Content -Path $logFilePath -Value $message
    } else {
        Write-Output "User with File Number $fileNumber not found in Active Directory."
        Add-Content -Path $logFilePath -Value "User with File Number $fileNumber not found in Active Directory."
    }
}

