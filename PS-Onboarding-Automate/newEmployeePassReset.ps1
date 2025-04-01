# This script will reset the password of the user on their start date to a generic password which will then require a reset on first login. 
# This will trigger the morning of the users start date 
# This script is designed to be run on an Azure Automation Runbook using system managed identity

# Required Graph Permissions: "User.ReadWrite.All", "Directory.Read.All", "UserAuthenticationMethod.ReadWrite.All", "Mail.Send"
# "Directory.AccessAsUser.All" is not assignable to application but req for password Reset
# Assigned "User Administrator" role to the app instead

######################
## Import & Connect ##
######################

# Import the modules
Import-module 'az.accounts'
Import-module 'Microsoft.Graph.Users'
Import-module 'Microsoft.Graph.Authentication'
Import-Module 'Microsoft.Graph.Users.Actions'

# Connect to Azure with the System Managed Identity
Connect-AzAccount -Identity

# Connect to Graph with the System Managed Identity
Connect-MgGraph -Identity 

####################
## Storage Acount ##
####################

$logTime = Get-Date -Format "yyyy-MM-dd"
$storageAccountName = "<your_storage_account>" # Storage account name
$containerName = "<your_container>" # Container name
$logFileName = "$logTime newEmployeeLog.txt" # Name of the exported data file
$LogFilePath = "$env:Temp\$logTime newEmployeeLog.txt"

###############
## Log Setup ##
###############
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $LogFilePath -Value "`n$TimeStamp - Password reset initiated for users starting today:"

################
## Main Start ##
################

# Retrieve users and check for upcoming start date
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype, mail
$CheckDate = Get-Date
#$MatchingUsers = $Employees | Where-Object {($_.EmployeeHireDate -as [datetime]).Date -eq $CheckDate.Date} #| Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, Id, employeeHireDate -AutoSize
$MatchingUsers = $Employees | Where-Object {
    ($_."EmployeeHireDate") -and
    ([datetime]::Parse($_.EmployeeHireDate).Date -eq $CheckDate.Date)
}

# Log: Output matched users based on hire date
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
                $NewPassword = "Welcome1"

                # Reset the user's password
                Get-MgUser -UserId $User.Id -Property DisplayName, Id, employeeHireDate, manager, mail, jobTitle
                Update-MgUser -UserId $User.Id -PasswordProfile @{
                    Password = $NewPassword
                    #ForceChangePasswordNextSignIn = $false #Currently when set to true it resets but then does not accept "old" password when resetting. 
                }
                
                ########################
                ## Send Manager Email ##
                ########################

                # Grab ID of Manager 
                $managerId = Get-MgUserManager -UserID $User.Id 

                # Grab additional properties of manager (Get-MgUserManager stores additional properties as a dict)
                $manager = Get-MgUser -UserId $managerId.Id -Property DisplayName, mail, Id, jobTitle

                # Email Parmeters 
                $params = @{
                    message = @{
                        subject = "New Employee: $($User.DisplayName)"
                        body = @{
                            contentType = "Text"
                            content = @"
Hi $($manager.DisplayName),

This is a reminder you have a new employee starting today ($($User.employeeHireDate)):

Name: $($User.DisplayName)
Job Title: $($User.jobTitle)
Email: $($User.mail)


Please ensure onboarding tasks are completed.
"@
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
                Add-Content -Path $LogFilePath -Value "Password reset for user: $($User.DisplayName)"
                Write-Output "Password reset for user: $($User.DisplayName)"
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
    Add-Content -Path $LogFilePath -Value "No users starting today"
    Write-Output "No users starting today."
}

##############################
## Send Log To Storage Blob ##
##############################

# Create the storage context directly with the managed identity
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName 
$blobs = Get-AzStorageBlob -Container $containerName -Context $storageContext
$blobs | ForEach-Object { $_.Name }

# Upload the file to the specified blob storage container
Set-AzStorageBlobContent -File $LogFilePath -Container $containerName -Blob $logFileName -Context $storageContext -Force


#########
## end ##
#########