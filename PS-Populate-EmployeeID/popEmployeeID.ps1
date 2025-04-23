# This takes a .csv that has 'First Name' and 'Last Name' columns and queries AD in order to populate a "EmployeeID" column. 
# Best if run on an on-prem Domain Controller as Admin. 
# Due to this organizations email format (firstname.lastname@domain.com) it will use this to query. 

Import-Module ActiveDirectory

# Path to your CSV
$inputCsvPath = "C:\id.csv"
$outputCsvPath = "C:\id_with_employeeid.csv"
$defaultDomain = "yourdomain.com"  # Change this to your domain

# Import the CSV
$users = Import-Csv -Path $inputCsvPath

# Loop through each row and try to find the EmployeeID
$updatedUsers = foreach ($user in $users) {
    $email = "$($user.'First Name').$($user.'Last Name')@$defaultDomain"

    # Search AD by email
    $adUser = Get-ADUser -Filter {Mail -eq $email} -Properties EmployeeID

    if ($adUser) {
        $user.EmployeeID = $adUser.EmployeeID
    } else {
        $user.EmployeeID = "NOT FOUND"
    }

    $user
}

# Export updated data
$updatedUsers | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Host "Done! Output saved to $outputCsvPath"
Import-Module ActiveDirectory