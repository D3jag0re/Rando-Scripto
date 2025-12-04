# This script compares local files listed in a CSV to files in a SharePoint document library.
# It outputs a CSV showing which local files are newer, older, or the same as their SharePoint counterparts.   

param(
    [string]$LocalCsv   = ".\directory_listing.csv",
    [string]$SiteUrl    = "https://domain.sharepoint.com/sites/department/",
    [string]$Library    = "Shared Documents",
    [string]$FolderRelativePath = "Shared Documents/FolderA/FolderB",
    [string]$OutputCsv  = ".\LocalVsSP.csv",
    [string]$ClientId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
)

############################
# 1. Connect to SharePoint #
############################

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

###########################
# 2. Load local file list #
###########################

$localFiles = Import-Csv $LocalCsv |
    Where-Object { -not [bool]::Parse(($_.PSIsContainer.ToString())) } |  # keep only files
    Select-Object @{Name='Name';Expression={ Split-Path $_.FullName -Leaf }},
                  @{Name='LocalPath';Expression={ $_.FullName }},
                  @{Name='LocalModified';Expression={ [datetime]$_.LastWriteTime }}

###########################
# 3. Get SharePoint files #
###########################

<#
# Recursive view of the whole library
$spItems = Get-PnPListItem -List $Library -PageSize 2000 `
    -Fields "FileLeafRef","FileRef","Modified" `
    -Query "<View Scope='RecursiveAll' />"

$spFiles = $spItems | Where-Object { $_.FileSystemObjectType -eq 'File' } | ForEach-Object {
    [pscustomobject]@{
        Name        = $_["FileLeafRef"]
        SPPath      = $_["FileRef"]       # server-relative URL
        SPModified  = [datetime]$_["Modified"]
    }
}
#>
# Recursively get all *files* under the specific folder
$spItems = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderRelativePath -ItemType File -Recursive

Write-Host "Found $($spItems.Count) files in SharePoint under '$FolderRelativePath'"

$spFiles = $spItems | ForEach-Object {
    [pscustomobject]@{
        Name       = $_.Name                        # filename only
        SPPath     = $_.ServerRelativeUrl           # /sites/.../Shared Documents/Business Development/Cost estimates/...
        SPModified = [datetime]$_.TimeLastModified
    }
}


###########################################
# 4. Build an index of SharePoint by name #
###########################################

# NOTE: if you have duplicate filenames in different folders,
# this will only keep the *last* one seen for that name.
$spIndex = @{}
foreach ($f in $spFiles) {
    $spIndex[$f.Name] = $f
}

##########################################
# 5. Join local ↔ SharePoint on filename #
##########################################

$comparison = foreach ($lf in $localFiles) {
    if ($spIndex.ContainsKey($lf.Name)) {
        $sp = $spIndex[$lf.Name]

        # Compare modified dates
        $status = if ($lf.LocalModified -gt $sp.SPModified) {
            "LocalNewer"
        }
        elseif ($lf.LocalModified -lt $sp.SPModified) {
            "SharePointNewer"
        }
        else {
            "Same"
        }

        [pscustomobject]@{
            Name          = $lf.Name
            LocalPath     = $lf.LocalPath
            SPPath        = $sp.SPPath
            LocalModified = $lf.LocalModified
            SPModified    = $sp.SPModified
            Status        = $status
        }
    }
}

##############################
# 6. Output / export results #
##############################

$comparison | Sort-Object Name | Export-Csv -Path $OutputCsv -NoTypeInformation

Write-Host "Done. Results exported to $OutputCsv"
