<# This script exports disabled Entra ID (Azure AD) users and their group memberships to CSV.
# Runs in current user context (interactive login), no install check.

########################
#### Prequisites #######
########################    

Microsoft.Graph module must already be installed.
Permissions: User.Read.All, Group.Read.All, Directory.Read.All
#>


# Import Microsoft Graph SDK modules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

####################

#[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position=0)]
  [string]$OutputCsv,

  [bool]$AllGroups = $true  # true = transitive (nested) memberships, false = direct only
)

$ErrorActionPreference = 'Stop'




# Connect to Microsoft Graph
$scopes = @('User.Read.All', 'Group.Read.All', 'Directory.Read.All')
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "Querying disabled users..." -ForegroundColor Cyan

$props = 'id,displayName,userPrincipalName,accountEnabled'
$disabledUsers = Get-MgUser -Filter "accountEnabled eq false" -ConsistencyLevel eventual -All -Property $props

if (-not $disabledUsers) {
    Write-Warning "No disabled users found."
    @() | Select-Object UserPrincipalName,DisplayName,AccountEnabled,GroupCount,Groups |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutputCsv
    Write-Host "Empty CSV created: $OutputCsv"
    return
}

Write-Host ("Found {0} disabled users..." -f $disabledUsers.Count) -ForegroundColor Cyan

$results = New-Object System.Collections.Generic.List[object]
$i = 0

foreach ($u in $disabledUsers) {
    $i++
    Write-Progress -Activity "Resolving group memberships" -Status "$($u.UserPrincipalName)" -PercentComplete (($i/$($disabledUsers.Count))*100)

    if ($AllGroups) {
        $groups = Get-MgUserTransitiveMemberOf -UserId $u.Id -All |
                  Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' }
    } else {
        $groups = Get-MgUserMemberOf -UserId $u.Id -All |
                  Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' }
    }

    $groupNames = ($groups | Select-Object -ExpandProperty DisplayName) -join '; '

    $results.Add([pscustomobject]@{
        UserPrincipalName = $u.UserPrincipalName
        DisplayName       = $u.DisplayName
        AccountEnabled    = $u.AccountEnabled
        GroupCount        = ($groups | Measure-Object).Count
        Groups            = $groupNames
    })
}

$results | Sort-Object UserPrincipalName |
    Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutputCsv

Write-Host ("Done. Exported {0} rows to {1}" -f $results.Count, $OutputCsv) -ForegroundColor Green
