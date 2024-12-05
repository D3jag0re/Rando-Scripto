# This script takes computers from a csv and moves them to a specific OU. 
# It was initially created to move shared devices to their own OU. Shared devices were defined in a csv. 

# Set the target OU where the inactive devices will be moved
$TargetOU = "OU=InactiveComputers,DC=yourdomain,DC=com"
$excludedOUs = @(
            'OU=Computers,OU=app,OU=site,DC=comp,DC=local'
            'OU=Servers,OU=app,OU=site,DC=comp,DC=local'
        )

# Define the path to your CSV file and the log file
$csvFilePath = "C:\path\to\file.csv"
$logFilePath = "C:\path\to\log.txt"

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV file
$computers= Import-Csv -Path $csvFilePath

# Loop through each row
foreach ($computer in $computers) {
    # Extract Hostname
    $hostname = $computer."Hostname"

    # Search for the computer in AD by hostname 
    $adComputer = Get-ADComputer -Filter { Name -eq $hostname } -Properties DistinguishedName

    if ($adComputer) {
        # Check if the computer's Distinguished Name is in one of the excluded OUs
        $computerDN = $adComputer.DistinguishedName
        $isInExcludedOU = $excludedOUs | ForEach-Object { $computerDN -like "*$_*" }

        if (-not $isInExcludedOU) {
            # If the computer is not in an excluded OU, move it to the target OU
            try {
                Move-ADObject -Identity $adComputer.DistinguishedName -TargetPath $TargetOU
                $logMessage = "Moved $hostname to $TargetOU at $(Get-Date)"
            } catch {
                $logMessage = "Failed to move $hostname : $_"
            }
        } else {
            $logMessage = "$hostname is in an excluded OU and will not be moved."
        }
    } else {
        $logMessage = "$hostname not found in Active Directory."
    }

    # Log the result of each computer's processing
    Add-Content -Path $logFilePath -Value $logMessage
}





















# Log the script end time with a timestamp
$endTime = "Script ended at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $endTime