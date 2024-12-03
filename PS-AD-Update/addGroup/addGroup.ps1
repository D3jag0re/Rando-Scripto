# Takes a list of users from a csv and adds to a single group 

# Variables 
$aDattribute='sAMAccountNAme' #AD Attribute to use for lookup / assignment 
$csvAttribute='name' #Header in csv you want to pull from
$targetGroup='VPN_Users' # AD Group to put users in

# Paths to csv / logs:
$csvFilePath = "C:\path\to\your\file.csv"
$logFilePath = "C:\path\to\addGrouplog.txt"

# Log the script start time with a timestamp
$startTime = "Script started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $startTime

# Import the CSV File 
$users = Import-Csv -Path $csvFilePath

# Loop through each row and pull desired key attribute
foreach ($user in $users) {
    # Extract necessary values from the CSV Row
    $key = $user.$csvAttribute

    # Search for the AD user with the matching attribute 
    $adUser = Get-ADUser -Filter { $aDattribute -eq $key } -Properties $aDattribute

    if ($aduser) {
        Add-ADGroupMember -Identity $targetGroup -Members $adUser.$aDattribute 
        $message = "Added $($adUser.SamAccountName) to $($targetGroup)"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message   
    } else {
        $message = "error for $($adUser.SamAccountName)"
        Write-Host $message
        Add-Content -Path $logFilePath -Value $message
    }
}