# Installs the watchguard ssl vpn on client machine silently 

# Download Client (12.11)
#curl https://cdn.watchguard.com/SoftwareCenter/Files/MUVPN_SSL/12_11/WG-MVPN-SSL_12_11.exe -o watchguardinstall.exe

#watchguardinstall.exe /silent /verysilent/tasks=desktopicon

# Script to silently install WatchGuard SSL VPN and verify desktop icon and installer

# Define variables
$downloadUrl = "https://cdn.watchguard.com/SoftwareCenter/Files/MUVPN_SSL/12_11/WG-MVPN-SSL_12_11.exe"
$installerPath = "watchguardinstall.exe"
$desktopIconName = "Mobile VPN with SSL client.lnk"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$installationPath = "C:\Program Files (x86)\WatchGuard\WatchGuard Mobile VPN with SSL"
$appExecutable = "wgsslvpnc.exe"

# Step 1: Download the installer
Write-Host "Starting download of WatchGuard SSL VPN installer..."
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -ErrorAction Stop
    Write-Host "Download completed successfully."
} catch {
    Write-Host "Error: Failed to download the installer. $_"
    exit 1
}

# Step 2: Install the software silently
Write-Host "Starting the silent installation of WatchGuard SSL VPN..."
try {
    Start-Process -FilePath $installerPath -ArgumentList "/silent", "/verysilent", "/tasks=desktopicon" -Wait -ErrorAction Stop
    Write-Host "Installation completed successfully."
} catch {
    Write-Host "Error: Installation failed. $_"
    exit 1
}

# Step 3: Verify if the installer executable exists in the installation directory
Write-Host "Checking if the installer executable exists in the installation directory..."
try {
    $fullInstallerPath = Join-Path -Path $installationPath -ChildPath $appExecutable
    if (Test-Path $fullInstallerPath) {
        Write-Host "Installer executable found: $fullInstallerPath"
    } else {
        Write-Host "Error: Installer executable not found at $fullInstallerPath."
        exit 1
    }
} catch {
    Write-Host "Error: Failed to verify the installer executable. $_"
    exit 1
}

# Step 4: Verify if the desktop icon exists
Write-Host "Verifying the creation of the desktop icon..."
try {
    $iconPath = Join-Path -Path $desktopPath -ChildPath $desktopIconName
    if (Test-Path $iconPath) {
        Write-Host "Desktop icon found: $iconPath"
    } else {
        Write-Host "Error: Desktop icon not found."
        exit 1
    }
} catch {
    Write-Host "Error: Failed to verify desktop icon. $_"
    exit 1
}

Write-Host "Script execution completed successfully."
