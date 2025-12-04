# This script lists all files and directories in a specified path and exports the details to a CSV file.
# If no csv is needed, comment out last line and remove pipe from previous line.

$path = "C:\Path\To\Folder"
$exportPath = ".\directory_listing.csv"

Get-ChildItem $path -Recurse |
    Select-Object FullName, PSIsContainer, Length, LastWriteTime |
    Export-Csv -Path $exportPath -NoTypeInformation
