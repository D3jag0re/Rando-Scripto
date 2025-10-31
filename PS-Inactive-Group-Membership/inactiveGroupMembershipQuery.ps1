# This script queries entra for users who are inactive (disabled) and who are still members of groups
# Replace groupId1 and groupId2 with the actual group IDs you want to compare.

# Import Microsoft Graph SDK modules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

# Connect to Microsoft Graph (e.g., using managed identity or interactive login)
Connect-MgGraph -Scopes "GroupMember.Read.All", "User.Read.All"

