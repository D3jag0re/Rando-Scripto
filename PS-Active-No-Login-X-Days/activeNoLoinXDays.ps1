<#
Find enabled on-prem AD users who haven't logged in for X days.
- Uses LastLogonDate (replicated from lastLogonTimestamp; ~9–14 day lag).
- Great for 30/60/90+ day inactivity.
- Hardcoded config, no module checks, no parameters.
#>

########## CONFIG (edit these) ##########
$Days                  = 90                 # set to 30 or 90, etc.
$IncludeNeverLoggedOn  = $true              # include users with no LastLogonDate
$SearchBase            = ""                 # e.g. "OU=Staff,OU=Users,DC=example,DC=com" (empty = whole domain)

# Optional exclusions (useful in real envs)
$ExcludeSamLike        = '^svc_|^adm_|^sys_' # regex on SamAccountName; empty "" to disable

# Output controls
$ShowTable             = $true
$TableRowLimit         = 100
$CsvPath               = ".\inactive-users-$Days-days.csv"   # set "" to skip CSV export
$TableColumns          = @('SamAccountName','LastLogonDate','DaysSinceLastLogon','Department','Title')
#########################################

$InactiveDate = (Get-Date).AddDays(-$Days)

# Pull enabled users (optionally scoped)
$props = @('SamAccountName','Name','UserPrincipalName','Enabled','LastLogonDate','whenCreated','Department','Title','DistinguishedName')
$splat = @{ Filter = "Enabled -eq `$true"; Properties = $props }
if ($SearchBase) { $splat.SearchBase = $SearchBase }

$enabled = Get-ADUser @splat

# Optional exclude by SamAccountName pattern(s)
if ($ExcludeSamLike) {
    $enabled = $enabled | Where-Object { $_.SamAccountName -notmatch $ExcludeSamLike }
}

# Older than cutoff (replicated LastLogonDate)
$olderThan = $enabled | Where-Object { $_.LastLogonDate -and $_.LastLogonDate -lt $InactiveDate }

# Optionally include never-logged-on users (no LastLogonDate)
$neverLogged = if ($IncludeNeverLoggedOn) { $enabled | Where-Object { -not $_.LastLogonDate } } else { @() }

$users = @($olderThan + $neverLogged)

# Project results with DaysSinceLastLogon and tidy output
$results = $users |
  Select-Object @{
      Name='DaysSinceLastLogon'; Expression = {
        if ($_.LastLogonDate) { [int]((Get-Date) - $_.LastLogonDate).TotalDays } else { $null }
      }
    },
    SamAccountName, Name, UserPrincipalName, Enabled, LastLogonDate, whenCreated, Department, Title, DistinguishedName |
  Sort-Object -Property DaysSinceLastLogon, Name -Descending

# Console table
if ($ShowTable -and $TableRowLimit -gt 0) {
    if ($results.Count -eq 0) {
        Write-Host "No users matched. Cutoff: $($InactiveDate.ToString('yyyy-MM-dd'))  (Days: $Days, IncludeNeverLoggedOn: $IncludeNeverLoggedOn)"
    } else {
        $toShow = $results | Select-Object -First $TableRowLimit
        $availableCols = $toShow[0].PSObject.Properties.Name
        $cols = if ($TableColumns) { $TableColumns | Where-Object { $_ -in $availableCols } } else { @('SamAccountName','LastLogonDate','DaysSinceLastLogon','Department','Title') }
        $toShow | Format-Table $cols -AutoSize | Out-Host
        Write-Host "`nTotal results: $($results.Count)  (showing first $([Math]::Min($TableRowLimit,$results.Count)))  Cutoff: $($InactiveDate.ToString('yyyy-MM-dd'))"
    }
}

# CSV export
if ($CsvPath) {
    if ($results.Count -gt 0) {
        try { $resolved = (Resolve-Path $CsvPath -ErrorAction Stop).Path } catch { $resolved = $CsvPath }
        $results | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CsvPath
        Write-Host "Exported $($results.Count) rows to $resolved"
    } else {
        Write-Host "CSV export skipped: no results. (CsvPath: '$CsvPath')"
    }
}

# Return objects (pipeline-friendly)
$results
