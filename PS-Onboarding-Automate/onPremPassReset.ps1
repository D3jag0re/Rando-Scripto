# This is an on-rem AD script being used in a hybrid environment.
# This script will reset the password of the user on their start date to a generic password which will then require a reset on first login. 
# This uses 'msDS-CloudExtensionAttribute1' for start date and is formatted for entra in YYYYMMDD080000.0Z format 

########################
## Import And Connect ##
########################

Import-Module ActiveDirectory

###############
## Setup Log ##
###############

# Get today's date and target AD format
$todayDate = Get-Date -Format "yyyyMMdd"
$targetDate = "${todayDate}080000.0Z"

# Prepare log file
$logDate = Get-Date -Format "yyyy-MM-dd"
$logPath = "C:\Logs\ADPasswordReset_$logDate.log"

# Ensure log directory exists
$logDir = Split-Path $logPath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Header
Add-Content -Path $logPath -Value "==== Password Reset Log: $logDate ===="

##########
## Main ##
##########

# Get users whose start date is today
$users = Get-ADUser -Filter { msDS-CloudExtensionAttribute1 -eq $targetDate } -Properties msDS-CloudExtensionAttribute1

if ($users.Count -eq 0) {
    Add-Content -Path $logPath -Value "No users found with start date of today ($targetDate)."
} else {
    foreach ($user in $users) {
        try {
            Set-ADAccountPassword -Identity $user.DistinguishedName -Reset -NewPassword (ConvertTo-SecureString "Welcome1" -AsPlainText -Force)
            Set-ADUser -Identity $user.DistinguishedName -ChangePasswordAtLogon $true

            $logMsg = "Password reset for user: $($user.SamAccountName)"
            Add-Content -Path $logPath -Value $logMsg
        } catch {
            $errMsg = "Failed to reset password for $($user.SamAccountName): $_"
            Add-Content -Path $logPath -Value $errMsg
        }
    }
}

# Footer
Add-Content -Path $logPath -Value "==== End of Log ====`n"

#########
## End ##
#########