<# 
.SYNOPSIS
Report authentication methods for members of an Entra ID group.

.PREREQS
Install-Module Microsoft.Graph -Scope CurrentUser

PERMS (delegated)
- GroupMember.Read.All
- UserAuthenticationMethod.Read.All

NOTE
This counts auth methods returned by /authentication/methods (includes password method object).
If you want "MFA methods only", see the $ExcludePassword switch below.
#>

$GroupId = '5ce5dfa8-a319-40e7-a77a-92a1e5eee77f'

#param(
#    [Parameter(Mandatory=$true)]
    #[string]$GroupId,

    #[switch]$ExcludePassword,

    #[int]$ThrottleMs = 150
#)

#################################
# --- Connect (interactive) --- #
#################################

$scopes = @("GroupMember.Read.All","UserAuthenticationMethod.Read.All")
Connect-MgGraph -Scopes $scopes | Out-Null

function Get-AuthMethodSummary {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserId
    )

    # Returns objects like:
    # microsoft.graph.passwordAuthenticationMethod
    # microsoft.graph.microsoftAuthenticatorAuthenticationMethod
    # microsoft.graph.fido2AuthenticationMethod
    # microsoft.graph.windowsHelloForBusinessAuthenticationMethod
    # microsoft.graph.phoneAuthenticationMethod
    # microsoft.graph.emailAuthenticationMethod
    # etc.
    $methods = Get-MgUserAuthenticationMethod -UserId $UserId -All -ErrorAction Stop

    if ($ExcludePassword) {
        $methods = $methods | Where-Object { $_.AdditionalProperties.'@odata.type' -ne '#microsoft.graph.passwordAuthenticationMethod' }
    }

    $types = $methods | ForEach-Object {
        # @odata.type is in AdditionalProperties for this cmdlet
        ($_.AdditionalProperties.'@odata.type' -replace '^#microsoft\.graph\.', '')
    }

    [pscustomobject]@{
        MethodCount = @($methods).Count
        MethodTypes = ($types | Sort-Object -Unique) -join ", "
    }
}
##########################################
# --- Get group members (users only) --- #
##########################################

$members = Get-MgGroupMember -GroupId $GroupId -All -ErrorAction Stop

# Filter to user objects only (groups/devices/servicePrincipals can also be members)
$userMembers = $members | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user' }

$report = foreach ($m in $userMembers) {
    $userId = $m.Id

    # Pull a few user fields (UPN/displayName) for nicer output
    $u = Get-MgUser -UserId $userId -Property "id,displayName,userPrincipalName,accountEnabled" -ErrorAction Stop

    try {
        $summary = Get-AuthMethodSummary -UserId $userId

        [pscustomobject]@{
            DisplayName       = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
            AccountEnabled    = $u.AccountEnabled
            MethodCount       = $summary.MethodCount
            MethodTypes       = $summary.MethodTypes
            HasMultiple       = ($summary.MethodCount -ge 2)
        }
    }
    catch {
        [pscustomobject]@{
            DisplayName       = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
            AccountEnabled    = $u.AccountEnabled
            MethodCount       = $null
            MethodTypes       = $null
            HasMultiple       = $null
            Error             = $_.Exception.Message
        }
    }

    Start-Sleep -Milliseconds 150
}

##################
# --- Output --- #
##################

$report |
    Sort-Object HasMultiple, DisplayName |
    Format-Table -AutoSize

# Optional: export
$report | Export-Csv ".\group-auth-methods.csv" -NoTypeInformation -Encoding UTF8

# Optional: just users with multiple
# $report | Where-Object HasMultiple | Sort-Object DisplayName | Format-Table -AutoSize