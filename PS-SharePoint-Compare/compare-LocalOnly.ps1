# This script compares local files listed in a CSV to files in a SharePoint document library.
# It outputs a CSV listing files that exist locally but not in SharePoint.

param(
    # CSV exported from your file server scan
    [string]$LocalCsv   = ".\directory_listing.csv",

    # Business Development site
    [string]$SiteUrl    = "https://domain.sharepoint.com/sites/siteName",

    # Target folder within the document library (site-relative, no leading slash)
    [string]$FolderRelativePath = "Shared Documents/FolderA/FolderB",

    # Output CSV for local-only files
    [string]$OutputCsv  = ".\LocalOnlyFiles.csv",

    # Your PnP app registration Client ID
    [string]$ClientId   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
)

Import-Module PnP.PowerShell -ErrorAction Stop

############################
# 1. Connect to SharePoint #
############################

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

###########################
# 2. Load local file list #
###########################

$localFiles = Import-Csv $LocalCsv |
    Where-Object { -not [bool]::Parse(($_.PSIsContainer.ToString())) } |  # keep only files
    Select-Object @{
        Name       = 'Name'
        Expression = { Split-Path $_.FullName -Leaf }
    },
    @{
        Name       = 'LocalPath'
        Expression = { $_.FullName }
    },
    @{
        Name       = 'LocalModified'
        Expression = { [datetime]$_.LastWriteTime }
    }

###########################
# 3. Get SharePoint files #
###########################

# Recursively get all *files* under the specific folder
$spItems = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderRelativePath -ItemType File -Recursive

Write-Host "Found $($spItems.Count) files in SharePoint under '$FolderRelativePath'"

$spFiles = $spItems | ForEach-Object {
    [pscustomobject]@{
        Name       = $_.Name                        # filename only
        SPPath     = $_.ServerRelativeUrl
        SPModified = [datetime]$_.TimeLastModified
    }
}

###########################################
# 4. Build an index of SharePoint by name #
###########################################

$spIndex = @{}
foreach ($f in $spFiles) {
    $spIndex[$f.Name] = $f
}

#############################################################
# 5. Find files that are local but NOT present in SharePoint #
#############################################################

$localOnly = foreach ($lf in $localFiles) {
    if (-not $spIndex.ContainsKey($lf.Name)) {
        [pscustomobject]@{
            Name          = $lf.Name
            LocalPath     = $lf.LocalPath
            LocalModified = $lf.LocalModified
        }
    }
}

##############################
# 6. Output / export results #
##############################

$localOnly |
    Sort-Object Name |
    Export-Csv -Path $OutputCsv -NoTypeInformation

Write-Host "Done. Local-only files exported to $OutputCsv"
