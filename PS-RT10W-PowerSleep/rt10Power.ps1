# ============================================================== #
# Honeywell RT10W - AutoLogon + Lock Prevention + Power Settings #
# ============================================================== #

# Define .reg content
$RegContent = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
"AutoAdminLogon"="1"
"DefaultUserName"="USERNAME"
"DefaultPassword"="PASSWORD"
"DefaultDomainName"="DOMAIN"

; ==============================================
; Disable machine inactivity lock (all users)
; ==============================================
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
"InactivityTimeoutSecs"=dword:00000000

; ==============================================
; Disable password on wake (battery & AC) - system wide
; ==============================================
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51]
"ACSettingIndex"=dword:00000000
"DCSettingIndex"=dword:00000000

; ==============================================
; Disable screen saver (current user)
; ==============================================
[HKEY_CURRENT_USER\Control Panel\Desktop]
"ScreenSaveActive"="0"

; ==============================================
; Set Power Button Action (legacy reg path, will override with powercfg)
; ==============================================
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\381b4222-f694-41f0-9685-ff5bb260df2e\7516b95f-f776-4464-8c53-06167f40cc99\7648efa3-dd9c-4e3e-b566-50f929386280]
"ACSettingIndex"=dword:00000000
"DCSettingIndex"=dword:00000000
"@

# Save .reg file to temp location
$RegPath = "$env:TEMP\RT10W_Settings.reg"
Set-Content -Path $RegPath -Value $RegContent -Encoding ASCII

# Import registry file silently
Start-Process regedit.exe -ArgumentList "/s `"$RegPath`"" -Wait

# ======================================================
# Apply Power Button and No Lock on Wake Settings
# ======================================================

# Power button = Turn off display (4) for AC and DC
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 4
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 4

# No lock on wake (0) for AC and DC
powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0

# Apply the scheme
powercfg -setactive SCHEME_CURRENT

Write-Host "All settings applied successfully. You may need to restart for AutoLogon to take effect."