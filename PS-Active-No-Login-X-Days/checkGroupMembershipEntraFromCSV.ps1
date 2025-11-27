<#
Reads a CSV of UPNs, checks Microsoft Entra group membership for each user.
- Auth: user context via Connect-MgGraph (User.Read.All, Group.Read.All)
- Output: console table + optional CSV with per-group booleans
#>

# -------------------- CONFIG (edit) --------------------
$CsvPathIn     = ".\inactive-users-90-days.csv"
$UpnColumn     = "UserPrincipalName"      # column in CSV containing UPNs
$CsvPathOut    = ".\membership-check-results.csv"  # "" to skip exporting

# Define groups to check by **Object ID** (fast + unambiguous)
# Optionally give them friendly names for the output columns
$GroupsToCheck = @(
    @{ Name = "groupName1";            Id = "xxxxxxxx-d0xx-4xx4-xxxx-dabb9771xxxx" },
    @{ Name = "groupName2";        Id = "xxxxxxxx-a3xx-4xx7-xxxx-92a1e5eexxxx" }
)

# Console preview
$ShowTable     = $true
#$TableRowLimit = 50
# ------------------------------------------------------

# --- Auth (user context) ---
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All" | Out-Null

# --- Validate CSV ---
if (-not (Test-Path $CsvPathIn)) { throw "CSV not found: $CsvPathIn" }
$rows = Import-Csv -Path $CsvPathIn
if (-not $rows -or $rows.Count -eq 0) { throw "CSV has no rows: $CsvPathIn" }
if (-not ($rows[0].PSObject.Properties.Name -contains $UpnColumn)) { throw "CSV missing column '$UpnColumn'." }

# --- Helpers ---
function ConvertTo-ColName([string]$s) { if (-not $s) { return 'Group' }; return ($s -replace '[^\w]', '_') }

# Build a map of GroupId -> ColumnName for pretty output
$GroupIdToCol = @{}
foreach ($g in $GroupsToCheck) {
    if ([string]::IsNullOrWhiteSpace($g.Id)) { throw "Group '$($g.Name)' has no Id set." }
    $GroupIdToCol[$g.Id] = "Is_{0}" -f (ConvertTo-ColName $g.Name)
}

# --- Main: per-user membership check (transitive) ---
$report = foreach ($row in $rows) {
    $upn = $row.$UpnColumn
    if (-not $upn) { continue }

    try {
        # You can use UPN directly with -UserId in Mg SDK
        $user = Get-MgUser -UserId $upn -Property "Id,DisplayName,UserPrincipalName,AccountEnabled" -ErrorAction Stop
    } catch {
        Write-Warning "User not found or inaccessible: $upn"
        $obj = [ordered]@{
            UserPrincipalName = $upn
            FoundInTenant     = $false
            AccountEnabled    = $null
            MatchedCount      = 0
            MatchedGroups     = ""
        }
        foreach ($g in $GroupsToCheck) { $obj[$GroupIdToCol[$g.Id]] = $false }
        [pscustomobject]$obj
        continue
    }

    # POST /users/{id}/checkMemberGroups  (transitive)
    $uri  = "https://graph.microsoft.com/v1.0/users/$($user.Id)/checkMemberGroups"
    $body = @{ groupIds = ($GroupsToCheck.Id) } | ConvertTo-Json

    $resp = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType "application/json" -ErrorAction Stop
    $matchedIds = @($resp.value)  # ensure array

    # Make a readable list of matched group names
    $matchedNames = foreach ($mid in $matchedIds) {
        ($GroupsToCheck | Where-Object Id -eq $mid | Select-Object -ExpandProperty Name -First 1)
    } Where-Object { $_ }

    $obj = [ordered]@{
        UserPrincipalName = $user.UserPrincipalName
        DisplayName       = $user.DisplayName
        FoundInTenant     = $true
        AccountEnabled    = $user.AccountEnabled
        MatchedCount      = $matchedNames.Count
        MatchedGroups     = ($matchedNames -join '; ')
    }

    # Add per-group booleans
    foreach ($g in $GroupsToCheck) {
        $col = $GroupIdToCol[$g.Id]
        $obj[$col] = ($matchedIds -contains $g.Id)
    }

    [pscustomobject]$obj
}

# --- Console table (show all rows) ---
if ($ShowTable) {
    $report | Format-Table -AutoSize | Out-Host
    Write-Host "`nTotal rows: $($report.Count)"
}


# --- CSV export ---
if ($CsvPathOut) {
    $report | Export-Csv -Path $CsvPathOut -NoTypeInformation -Encoding UTF8
    Write-Host "Exported results to $CsvPathOut"
}
