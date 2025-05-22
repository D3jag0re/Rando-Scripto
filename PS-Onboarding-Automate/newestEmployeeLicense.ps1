# This is a modification from newEmployee2Day.ps1 
# Instead of triggering new users starting in two days, it will look for the last 20 created users, 
# check if they are in a license group, and if not, add them to the F3 group.
# This will help to elimnate timeline issues resulting from the 2 day start-date lookahead. 
# Comment out the block with {{ Add-MgGroupMember -GroupId $targetGroupId -BodyParameter @{  }} for Dry Run 

# This is written to run in an Azure Automation runbook as it assumes the managed identity

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
## Log Start ##
###############

$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $LogFilePath -Value "`n$TimeStamp - Starting group membership script for recent users"

#################################
## Group Settings (Hardcoded)  ##
#################################

$checkGroupIds = @(
    "11111111-aaaa-bbbb-cccc-111111111111",
    "22222222-dddd-eeee-ffff-222222222222",
    "33333333-gggg-hhhh-jjjj-333333333333"
)
$targetGroupId = "33333333-gggg-hhhh-iiii-333333333333"

##############################
## Get Recent Entra Users   ##
##############################

Add-Content -Path $LogFilePath -Value "Fetching recent users from Entra..."
$recentUsers = Get-MgUser -All -Filter "accountEnabled eq true and userType eq 'Member'"  -Property DisplayName,Id,CreatedDateTime | Sort-Object CreatedDateTime -Descending | Select-Object DisplayName,Id,CreatedDateTime -First 20

foreach ($user in $recentUsers) {
    $userId = $user.Id
    $displayName = $user.DisplayName
    $userPrincipalName = $user.UserPrincipalName

    Add-Content -Path $LogFilePath -Value "Processing user: $displayName ($userPrincipalName)"
    
    $isInAnyCheckGroup = $false

    foreach ($groupId in $checkGroupIds) {
        try {
            $isMember = Get-MgGroupMember -GroupId $groupId -All | Where-Object { $_.Id -eq $userId }

            if ($isMember) {
                $isInAnyCheckGroup = $true
                Add-Content -Path $LogFilePath -Value "User $displayName is already in group $groupId"
                break
            }
        } catch {
            Add-Content -Path $LogFilePath -Value "Error checking group $groupId for user $displayName : $_"
        }
    }

    if (-not $isInAnyCheckGroup) {
        try {
            Add-MgGroupMember -GroupId $targetGroupId -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
            }

            Add-Content -Path $LogFilePath -Value "User $displayName added to target group $targetGroupId"
        } catch {
            Add-Content -Path $LogFilePath -Value "Failed to add $displayName to target group: $_"
        }
    }
}


##############################
## Upload Log to Blob ##
##############################

Add-Content -Path $LogFilePath -Value "`n$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - Script completed."

$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName
Set-AzStorageBlobContent -File $LogFilePath -Container $containerName -Blob $logFileName -Context $storageContext -Force