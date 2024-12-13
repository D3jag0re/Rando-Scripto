# Script to create shortcut on desktop
## One Liner Version - To run as single command remotely when there are complications around running scripts.
# Full-Size version in ./shortcut.ps1

$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut([System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'Watchguard VPN.lnk')); $sc.TargetPath = "C:\Program Files (x86)\WatchGuard\WatchGuard Mobile VPN with SSL\wgsslvpnc"; $sc.WorkingDirectory = "C:\Program Files (x86)\WatchGuard\WatchGuard Mobile VPN with SSL\"; $sc.Save()
