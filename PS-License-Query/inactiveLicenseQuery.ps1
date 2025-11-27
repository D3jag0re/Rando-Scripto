# Inactive License Query Script
# This script queries Microsoft Graph to find inactive users with licenses.

Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"

# Replace with your licensing group object ID
#$groupId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Get members of the group who are users and disabled
$groupMembers = Get-MgGroupMember -GroupId $groupId -All 

# This will output a fancy list of users in the group of who is active and who is not
$disabledUsers = @()
$activeUsers = foreach ($member in $groupMembers) {
    $type = $member.AdditionalProperties.'@odata.type'

    if ($type -eq '#microsoft.graph.user') {
        try {
            $user = Get-MgUser -UserId $member.Id -Property "DisplayName,UserPrincipalName,AccountEnabled,AssignedLicenses" -ErrorAction Stop
            if ($user.AccountEnabled -eq $true) {
                # Optional debug log
                Write-Host "✅ Active user: $($user.DisplayName)"
                $user
            } else {
                Write-Host "🛑 Disabled user: $($user.DisplayName)"
                $disabledUsers += $user
            }
        } catch {
            Write-Warning "❌ Failed to resolve user $($member.Id): $_"
        }
    } else {
        Write-Host "⚠️ Skipped non-user object: $($member.Id)"
    }
}

# Show output of disabled users Only 
$disabledUsers | Select-Object DisplayName, UserPrincipalName
# Optional: Show output of active users
#$activeUsers | Select-Object DisplayName, UserPrincipalName

# Export to CSV - Uncomment if needed
# $disabledUsers | Select DisplayName, UserPrincipalName | Export-Csv -Path "DisabledUsers.csv" -NoTypeInformation