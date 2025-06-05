# This script queries entra for users in two groups and returns which users are in both. 

# Import Microsoft Graph SDK modules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

# Connect to Microsoft Graph (e.g., using managed identity or interactive login)
Connect-MgGraph -Scopes "GroupMember.Read.All", "User.Read.All"

# Placeholder group IDs – replace with actual values
$groupId1 = "group_ID_1_here" # e.g., "f812d107-b9c7-4b18-aae7-e273444af453"
$groupId2 = "group_ID_2_here" # e.g., "5ce5dfa8-a319-40e7-a77a-92a1e5eee77f"

# Get members of both groups
$group1Members = Get-MgGroupMember -GroupId $groupId1 -All 
$group2Members = Get-MgGroupMember -GroupId $groupId2 -All 

# Extract just the Ids
$group1Ids = $group1Members.Id
$group2Ids = $group2Members.Id

# Find users in both groups
$commonIds = $group1Ids | Where-Object { $group2Ids -contains $_ }

# Get user details
$commonUsers = foreach ($id in $commonIds) {
    Get-MgUser -UserId $id -Property DisplayName, Mail, Id
}

# Outputs (uncomment as needed)
Write-Output "Common Users: `n"
$commonUsers | Select-Object DisplayName, Mail, Id