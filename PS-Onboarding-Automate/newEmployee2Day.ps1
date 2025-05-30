# This script will see which users are starting in 2 days, and add them to a license group
# This will trigger 2 days before Users start date 
# Email manager with name, job title, email, and alert them email is active.
# This script is designed to be run on an Azure Automation Runbook using system managed identity

# Required Graph Permissions: "User.ReadWrite.All", "Directory.Read.All", "UserAuthenticationMethod.ReadWrite.All", "Mail.Send", "GroupMember.ReadWrite.All"
# "Directory.AccessAsUser.All" is not assignable to application but req for password Reset
# Assigned "User Administrator" role to the app instead

######################
## Import & Connect ##
######################

# Import the modules
Import-module 'az.accounts'
Import-module 'Microsoft.Graph.Authentication'
Import-module 'Microsoft.Graph.Users'
Import-Module 'Microsoft.Graph.Users.Actions'
Import-Module 'Microsoft.Graph.Groups'

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
Add-Content -Path $LogFilePath -Value "`n$TimeStamp - Password reset initiated for users starting in 2 days:"

#################

# Retrieve users and check for upcoming start date
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype, mail
$CheckDate = (Get-Date).AddDays(2)
$MatchingUsers = $Employees | Where-Object {($_.EmployeeHireDate -as [datetime]).Date -eq $CheckDate.Date} #| Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, Id, employeeHireDate -AutoSize

# Log: Output matched users based on hire date
Add-Content -Path $LogFilePath -Value "Matched Users for License Assignment:"
$MatchingUsers | ForEach-Object {
    Add-Content -Path $LogFilePath -Value "Id: $($_.Id)"
    Add-Content -Path $LogFilePath -Value "DisplayName: $($_.DisplayName)"
    Add-Content -Path $LogFilePath -Value "UserPrincipalName: $($_.UserPrincipalName)"
    Add-Content -Path $LogFilePath -Value "EmployeeHireDate: $($_.EmployeeHireDate)"
    Add-Content -Path $LogFilePath -Value "---------------------------"
}

#################
# GroupID - Hardcoding this as v1 has everyone going into the same group. 
#################
$groupID = <your_group_id>

# Process matching users with error handling
if ($MatchingUsers.Count -gt 0) {
    foreach ($User in $MatchingUsers) {
        if ($User.Id -and $User.DisplayName) {
            try {
                # Reset the user's password
                Get-MgUser -UserId $User.Id -Property DisplayName, Id, employeeHireDate, manager, mail
                New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id
                
               
                ########################
                ## Send Manager Email ##
                ########################
<#
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
                            content = @"
Hi $($manager.DisplayName),

This is a reminder you have a new employee starting on ($($User.employeeHireDate)):

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
                        ccRecipients = @(
                            @{
                                emailAddress = @{
                                    address = ""
                                }
                            }
                        )
                }
                saveToSentItems = "true"
                }
                # Send Mail 
                Send-MgUserMail -UserId "$($manager.Id)" -BodyParameter $params
#>               
#################               
                # Log the password reset action
                Add-Content -Path $LogFilePath -Value "License Assigned to user: $($User.DisplayName)"
                Write-Output "License Assigned to user: $($User.DisplayName)"
                # Log Email
                Add-Content -Path $LogFilePath -Value "Email sent to manager: $($manager.mail) "
            } catch {
                # Log any errors during password reset
                Add-Content -Path $LogFilePath -Value "Failed to assign License for user: $($User.DisplayName) - Error: $_"
            }
        } else {
            # Log if user does not have required properties
            Add-Content -Path $LogFilePath -Value "Skipped user due to missing Id or DisplayName properties."
        }
    }
} else {
    Add-Content -Path $LogFilePath -Value "No users with a hire date in 2 days."
    Write-Output "No users with a hire date in 2 days."
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