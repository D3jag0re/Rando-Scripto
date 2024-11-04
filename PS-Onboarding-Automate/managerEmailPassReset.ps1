# This script will reset the password of the user, then send an email to their manager with their temporary password as well as start date details for the user. 
# This will trigger 3 days before Users start date 

############################################################################
# Check if Microsoft Graph PowerShell module is installed, and if not, install it. 
# Requires Microsoft Graph PowerShell SDK
if (!(Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Output "Microsoft Graph PowerShell module is not installed. Installing now..."
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
} else {
    Write-Output "Microsoft Graph PowerShell module is already installed."
}


function New-Password {
    param(
        [int]$Length = 8,
        [int]$Count = 1
    )
    
    $UpperCaseChars = [char[]]([char]'A'..[char]'Z')
    $LowerCaseChars = [char[]]([char]'a'..[char]'z')
    $NumberChars = [char[]]([char]'1'..[char]'9')
    $SpecialChars = [char[]]('!', '@', '#', '$', '%')
    
    for ($i = 1; $i -le $Count; $i++) {
        $PasswordChars = @()
        for ($j = 1; $j -le $Length; $j++) {
            switch (Get-Random -Minimum 1 -Maximum 5) {
                1 { $PasswordChars += $UpperCaseChars | Get-Random }
                2 { $PasswordChars += $LowerCaseChars | Get-Random }
                3 { $PasswordChars += $NumberChars | Get-Random }
                4 { $PasswordChars += $SpecialChars | Get-Random }
            }
        }
        $newpass = -join $PasswordChars
        Write-Output $newpass
    }
}
#New-Password 
#-Length 8 -Count 5

### Logs ###
# Log file path
$LogFilePath = ".\PasswordResetLog.txt"

# Log the date and time of the run
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $LogFilePath -Value "`n$TimeStamp - Password reset initiated for users starting in 3 days:"


# Grabs all users in directory and fins which start in X days (if any)

# Connect To Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.Read.All", "UserAuthenticationMethod.ReadWrite.All", "Directory.AccessAsUser.All", "Mail.Send"

# Retrieve users and check for upcoming start date
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype, mail
$CheckDate = (Get-Date).AddDays(3)
$MatchingUsers = $Employees | Where-Object {($_.EmployeeHireDate -as [datetime]).Date -eq $CheckDate.Date} #| Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, Id, employeeHireDate -AutoSize

<# Diagnostic: Output matched users based on hire date
Write-Output "Matched Users for password reset:"
$MatchingUsers | ForEach-Object {
    Write-Output "Id: $($_.Id)"
    Write-Output "DisplayName: $($_.DisplayName)"
    Write-Output "UserPrincipalName: $($_.UserPrincipalName)"
    Write-Output "EmployeeHireDate: $($_.EmployeeHireDate)"
    Write-Output "---------------------------"
}
#>

# Diagnostic: Output matched users based on hire date
Add-Content -Path $LogFilePath -Value "Matched Users for password reset:"
$MatchingUsers | ForEach-Object {
    Add-Content -Path $LogFilePath -Value "Id: $($_.Id)"
    Add-Content -Path $LogFilePath -Value "DisplayName: $($_.DisplayName)"
    Add-Content -Path $LogFilePath -Value "UserPrincipalName: $($_.UserPrincipalName)"
    Add-Content -Path $LogFilePath -Value "EmployeeHireDate: $($_.EmployeeHireDate)"
    Add-Content -Path $LogFilePath -Value "---------------------------"
}

# Process matching users with error handling
if ($MatchingUsers.Count -gt 0) {
    foreach ($User in $MatchingUsers) {
        if ($User.Id -and $User.DisplayName) {
            try {
                # Generate a new password
                $NewPassword = New-Password -Length 8 -Count 1

                # Reset the user's password
                Get-MgUser -UserId $User.Id -Property DisplayName, Id, employeeHireDate, manager, mail
                Update-MgUser -UserId $User.Id -PasswordProfile @{
                    Password = $NewPassword
                    ForceChangePasswordNextSignIn = $false #Currently when set to true it resets but then does not accept "old" password when resetting. 
                }
#################
                # Send Manager Email
                
                # Grab ID of Manager 
                $managerId = Get-MgUserManager -UserID $User.Id 

                # Grab additional properties of manager (Get-MgUserManager stores additional properties as a dict)
                $manager = Get-MgUser -UserId $managerId.Id -Property DisplayName, mail, Id

                # Email Parmeters 
                $params = @{
                    message = @{
                        subject = "New Employee: $($User.DisplayName)"
                        body = @{
                            contentType = "Text"
                            content = "Hi $($manager.DisplayName),

This is a reminder you have a new employee starting on $($User.employeeHireDate):

Name: $($User.DisplayName)
Email: $($User.mail)
Pass: $($NewPassword)"
                        }
                        toRecipients = @(
                            @{
                                emailAddress = @{
                                    address = "$($manager.Mail)"
                                    }
                            }
                        )
                        <#ccRecipients = @(
                            @{
                                emailAddress = @{
                                    address = ""
                                }
                            }
                        )#>
                }
                saveToSentItems = "true"
                }
                # Send Mail 
                Send-MgUserMail -UserId "$($manager.Id)" -BodyParameter $params
                
#################               
                # Log the password reset action
                Add-Content -Path $LogFilePath -Value "Password reset for user: $($User.DisplayName) $($NewPassword)"
                # Log Email
                Add-Content -Path $LogFilePath -Value "Password details send to $($manager.mail) "
            } catch {
                # Log any errors during password reset
                Add-Content -Path $LogFilePath -Value "Failed to reset password for user: $($User.DisplayName) - Error: $_"
            }
        } else {
            # Log if user does not have required properties
            Add-Content -Path $LogFilePath -Value "Skipped user due to missing Id or DisplayName properties."
        }
    }
} else {
    Add-Content -Path $LogFilePath -Value "No users with a hire date in 3 days."
}

######################################################################

# Will need "UserAuthenticationMethod.ReadWrite.All" if using temporaryAccessPass
# Get-MgUserManager -UserID $user.Id    - This returns the managerID
# Get-MgUser -UserId 1d9e6d49-87cb-4df3-825c-bdfa3690653f -Property Id,manager | format-list -Property *     To see all user properties 
# Setup service account for mailing, might be easier than using a service principal
