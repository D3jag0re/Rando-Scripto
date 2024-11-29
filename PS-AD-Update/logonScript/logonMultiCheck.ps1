# Note this is three different ones 

######################################################################################
## Script to pull the scriptPath attribute if it is anything but null or logon.vbs: ##
######################################################################################

# Import Active Directory module
Import-Module ActiveDirectory

# Get all users where scriptPath is not null or 'logon.vbs'
$usersWithCustomScriptPath = Get-ADUser -Filter * -Properties scriptPath | Where-Object {
    $_.scriptPath -and $_.scriptPath -ne 'logon.vbs'
}

# Output users with their scriptPath
$usersWithCustomScriptPath | Select-Object Name, SamAccountName, scriptPath


###############################################################
## Script to list users who have nothing set for scriptPath: ##
###############################################################

# Import Active Directory module
Import-Module ActiveDirectory

# Get all users where scriptPath is null or empty
$usersWithoutScriptPath = Get-ADUser -Filter * -Properties scriptPath | Where-Object {
    -not $_.scriptPath
}

# Output users
$usersWithoutScriptPath | Select-Object Name, SamAccountName

###############################################################
## Script to list users who have nothing set for scriptPath: ##
###############################################################

# Import Active Directory module
Import-Module ActiveDirectory

# Get all users where scriptPath is null or empty
$usersWithoutScriptPath = Get-ADUser -Filter * -Properties scriptPath | Where-Object {
    -not $_.scriptPath
}

# Set scriptPath to 'logon.vbs' for users without a scriptPath
foreach ($user in $usersWithoutScriptPath) {
    Set-ADUser -Identity $user.SamAccountName -ScriptPath 'logon.vbs'
    Write-Host "Updated scriptPath for user: $($user.SamAccountName)"
}

Write-Host "Completed updating scriptPath for all users with no existing value."
