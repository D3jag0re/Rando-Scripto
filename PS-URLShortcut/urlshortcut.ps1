# This Script adds a webmail url shortcut to the desktop. First it checks if onedrive folder exists, and if it does not, places in the local user desktop folder. 
# Used for deploying via Intune
# Replace <company> on line 7 with your company name / Onedrive name 

$new_object = New-Object -ComObject WScript.Shell
$desktop_path = "$env:USERPROFILE\Desktop"
$onedrive_path = "$env:USERPROFILE\OneDrive - <company>\Desktop"
$source_path = if(Test-Path $onedrive_path) { Join-Path -Path $onedrive_path -ChildPath "\Webmail.url" } else { Join-Path -Path $desktop_path -ChildPath "\Webmail.url" }
$source = $new_object.CreateShortcut($source_path)
$source.TargetPath = "https://outlook.office.com/"
$source.Save()
