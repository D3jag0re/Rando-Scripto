param(
    [int]$DaysInactive = 90,
    [string[]]$ExcludedAccounts = @(
        'Administrator',
        'localadmin',
        'DOMAIN\localadmin'
    ),
    [string[]]$ExcludedADGroups = @(
        'Domain Admins',
        'Profile Cleanup Exempt'
    ),
    [string]$LogPath = 'C:\Logs\ProfileCleanup.log',
    [switch]$WhatIfMode = $true
)

# Ensure log folder exists
$logFolder = Split-Path -Path $LogPath -Parent
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Writes a timestamped message to both the configured log file and standard output.
# Supports INFO and WARN/ERROR levels for structured logging.
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $line
    Write-Output $line
}

# Retrieves all user SamAccountNames that belong to the given AD groups.
# This allows the cleanup script to exclude profiles for users in exempt groups.
function Get-ExcludedGroupMembers {
    param(
        [string[]]$GroupNames
    )

    $members = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    try {
        # Load the ActiveDirectory module once so group membership can be queried.
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Log "ActiveDirectory module loaded successfully."
    }
    catch {
        Write-Log "Could not load ActiveDirectory module. Group-based exclusions will not be available. Error: $($_.Exception.Message)" 'WARN'
        return $members
    }

    foreach ($group in $GroupNames) {
        try {
            $groupMembers = Get-ADGroupMember -Identity $group -Recursive -ErrorAction Stop |
                Where-Object { $_.objectClass -eq 'user' } |
                Get-ADUser -Properties SamAccountName -ErrorAction Stop

            foreach ($member in $groupMembers) {
                if ($member.SamAccountName) {
                    [void]$members.Add($member.SamAccountName)
                }
            }

            Write-Log "Loaded exclusion group '$group' with $($groupMembers.Count) user member(s)."
        }
        catch {
            Write-Log "Failed to load members for AD group '$group'. Error: $($_.Exception.Message)" 'WARN'
        }
    }

    return $members
}

# Derives a candidate username from a profile folder path.
# Supports plain folder names and common .DOMAIN suffix formats.
function Get-ProfileUsernameInfo {
    param(
        [string]$ProfilePath
    )

    $leaf = Split-Path -Path $ProfilePath -Leaf

    # Handles examples like:
    # C:\Users\jsmith
    # C:\Users\jsmith.DOMAIN
    # C:\Users\jane.doe
    $samGuess = $leaf
    if ($leaf -match '^(?<name>.+?)\.[^.\\]+$') {
        $samGuess = $Matches['name']
    }

    [PSCustomObject]@{
        ProfileLeaf = $leaf
        SamGuess    = $samGuess
    }
}

Write-Log "========== Profile cleanup started =========="
Write-Log "DaysInactive = $DaysInactive"
Write-Log "Explicit exclusions = $($ExcludedAccounts -join ', ')"
Write-Log "AD group exclusions = $($ExcludedADGroups -join ', ')"
Write-Log "WhatIfMode = $WhatIfMode"

$cutoffDate = (Get-Date).AddDays(-$DaysInactive)
Write-Log "Profiles with LastUseTime older than $cutoffDate will be considered."

# Build exclusion sets
$explicitExclusions = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
foreach ($acct in $ExcludedAccounts) {
    [void]$explicitExclusions.Add($acct)

    # Also store unqualified name if DOMAIN\user format was supplied
    if ($acct -match '^[^\\]+\\(?<user>.+)$') {
        [void]$explicitExclusions.Add($Matches['user'])
    }
}

$groupExcludedSamAccounts = Get-ExcludedGroupMembers -GroupNames $ExcludedADGroups

# Get candidate profiles
try {
    $profiles = Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop
}
catch {
    Write-Log "Failed to enumerate user profiles. Error: $($_.Exception.Message)" 'ERROR'
    exit 1
}

foreach ($userProfile in $profiles) {
    try {
        $profilePath = $userProfile.LocalPath

        if ([string]::IsNullOrWhiteSpace($profilePath)) {
            Write-Log "Skipping profile with empty LocalPath." 'WARN'
            continue
        }

        if ($userProfile.Special) {
            Write-Log "Skipping special profile: $profilePath"
            continue
        }

        if ($userProfile.Loaded) {
            Write-Log "Skipping loaded profile: $profilePath"
            continue
        }

        if (-not $userProfile.LastUseTime) {
            Write-Log "Skipping profile with no LastUseTime: $profilePath" 'WARN'
            continue
        }

        $lastUse = [Management.ManagementDateTimeConverter]::ToDateTime($userProfile.LastUseTime)

        if ($lastUse -ge $cutoffDate) {
            Write-Log "Skipping recent profile: $profilePath (LastUseTime: $lastUse)"
            continue
        }

        $userInfo = Get-ProfileUsernameInfo -ProfilePath $profilePath
        $profileLeaf = $userInfo.ProfileLeaf
        $samGuess = $userInfo.SamGuess

        if ($explicitExclusions.Contains($profileLeaf) -or $explicitExclusions.Contains($samGuess)) {
            Write-Log "Skipping explicitly excluded profile: $profilePath"
            continue
        }

        if ($groupExcludedSamAccounts.Contains($samGuess)) {
            Write-Log "Skipping AD-group-excluded profile: $profilePath (matched SamAccountName: $samGuess)"
            continue
        }

        if ($WhatIfMode) {
            Write-Log "WHATIF: Would delete profile: $profilePath (LastUseTime: $lastUse)"
        }
        else {
            Write-Log "Deleting profile: $profilePath (LastUseTime: $lastUse)"
            Remove-CimInstance -InputObject $userProfile -ErrorAction Stop
            Write-Log "Successfully deleted profile: $profilePath"
        }
    }
    catch {
        Write-Log "Failed processing profile '$($userProfile.LocalPath)'. Error: $($_.Exception.Message)" 'ERROR'
    }
}

Write-Log "========== Profile cleanup finished =========="