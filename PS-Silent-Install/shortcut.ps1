# Script to create shortcut on desktop

# Define the path to the executable
$ExecutablePath = "C:\Program Files (x86)\WatchGuard\WatchGuard Mobile VPN with SSL\wgsslvpnc"

# Define the path to the Desktop
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define the shortcut file path
$ShortcutPath = Join-Path -Path $DesktopPath -ChildPath "Watchguard VPN.lnk"

# Create a WScript.Shell COM object
$WScriptShell = New-Object -ComObject WScript.Shell

# Create the shortcut
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $ExecutablePath
$Shortcut.WorkingDirectory = Split-Path -Path $ExecutablePath
$Shortcut.Save()

Write-Output "Shortcut created on the desktop at: $ShortcutPath"