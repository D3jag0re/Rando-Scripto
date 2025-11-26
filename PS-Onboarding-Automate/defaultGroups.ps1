# This script ensures that the most recently created users in Entra ID
# are members of a predefined set of default groups.
# No logging, just console output.
######################
## Import & Connect ##
######################

Import-Module Az.Accounts
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

# Connect to Azure with the System Managed Identity
Connect-AzAccount -Identiy

# Connect to Graph with the System Managed Identity
Connect-MgGraph -Identity

Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting default group membership check for recent users."

#################################
## Default Group IDs (Hardcoded)
#################################
# These are the groups that every new user *must* be a member of.
# Replace these with your own default group IDs as needed.
$defaultGroupIds = @(
    "0fxxxx18-xxxx-41xx-axx3-xxxxxxxxxxxf"
)

##############################
## Get Recent Entra Users   ##
##############################

Write-Output "Fetching the 20 most recently created enabled member users from Entra..."

# Note: include UserPrincipalName in the properties so we can log it
$recentUsers = Get-MgUser -All `
    -Filter "accountEnabled eq true and userType eq 'Member'" `
    -Property DisplayName, Id, CreatedDateTime, UserPrincipalName |
    Sort-Object CreatedDateTime -Descending |
    Select-Object DisplayName, Id, CreatedDateTime, UserPrincipalName -First 20

if (-not $recentUsers) {
    Write-Warning "No users returned. Exiting."
    return
}

Write-Output "Found $($recentUsers.Count) users. Checking default group membership..."

######################################
## Ensure Each User is in All Groups ##
######################################

foreach ($user in $recentUsers) {
    $userId            = $user.Id
    $displayName       = $user.DisplayName
    $userPrincipalName = $user.UserPrincipalName
    $created           = $user.CreatedDateTime

    Write-Output ""
    Write-Output "---------------------------------------------------------"
    Write-Output "Processing user: $displayName ($userPrincipalName)"
    Write-Output "Created: $created"
    Write-Output "---------------------------------------------------------"

    foreach ($groupId in $defaultGroupIds) {
        try {
            # Check if user is already a member of this group
            $isMember = Get-MgGroupMember -GroupId $groupId -All |
                        Where-Object { $_.Id -eq $userId }

            if ($isMember) {
                Write-Output "User '$displayName' is already a member of group $groupId"
                continue
            }

            # Add user to the group if not already a member
            Write-Output "User '$displayName' is NOT a member of group $groupId. Adding..."

            New-MgGroupMember -GroupId $groupId -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
            }

            Write-Output "Successfully added '$displayName' to group $groupId."
        }
        catch {
            Write-Warning "Error processing group $groupId for user '$displayName': $($_.Exception.Message)"
        }
    }
}

Write-Output ""
Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Finished default group membership check."
