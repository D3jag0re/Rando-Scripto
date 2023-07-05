# Offboarding Script For AAD / O365 

# ---------------------------------- #
# Functions 
# ---------------------------------- #

# This checks if the correct modules are installed in order to run the script. Prompts for install if not, and then connects to the service.

function Connect_MgGraph {
    $Module = ((Get-Module -Name Microsoft.Graph.Identity.DirectoryManagement -ListAvailable) -and (Get-Module -Name Microsoft.Graph.Users -ListAvailable) -and (Get-Module -Name Microsoft.Graph.Users.Actions -ListAvailable))
    if ($Module -eq $false) { 
        Write-Host "Microsoft Graph PowerShell module is not available"  -ForegroundColor yellow  
        $Confirm = Read-Host "Are you sure you want to install module? [Y] Yes [N] No" 
        if ($Confirm -match "[yY]") { 
            Write-host "Installing Microsoft Graph PowerShell module"
            Install-Module Microsoft.Graph -Scope AllUsers -AllowClobber -Force
        } 
        else { 
            Write-Host "Microsoft Graph module is required use Graph api.Please install module using Install-Module Microsoft.Graph cmdlet." -ForegroundColor Red
            Exit
        }
    }
    Write-Progress "Importing Required Modules..."
    Import-Module -Name Microsoft.Graph.Identity.DirectoryManagement
    Import-Module -Name Microsoft.Graph.Users
    Import-Module -Name Microsoft.Graph.Users.Actions
    Write-Progress "Connecting MgGraph Module..."
    Connect-MgGraph -Scopes Directory.ReadWrite.All, User.ReadWrite.All, Group.ReadWrite.All, Directory.AccessAsUser.All
    Select-MgProfile -Name "beta"
}

# Gather The User Info (need to implement forwarding and delegation option)
function user_info {
    $global:upn = Read-Host "Enter the user principal name (UPN) of the user who is being offboarded"
    
    # Get the user object from Azure AD
    try {
        $global:user = Get-MgUser -UserId $global:upn 
        Write-Host $global:upn selected 
    }
    catch {
        throw 
    }

    # Forwarding 
    do {
        $fwdbool = Read-Host "Does The User Mailbox Need To Be Forwarded? [Y] Yes [N] No"
        if ($fwdbool -notin 'Y', 'y', 'N', 'n') {
            Write-Host "Please enter a valid response."
        }
    } while ($fwdbool -notin 'Y', 'y', 'N', 'n')

    if ($fwdbool -in 'Y', 'y') {
        $global:fadd = Read-Host "Enter forwarding email address. If none, leave blank: "
    }
    else {
        Write-Host "No Forwarding Address Found, Mailbox Not Not Be Forwarded"
    }
    # Delegation
    do {
        $delbool = Read-Host "Does The User Mailbox Need To Be Delegated To Another User? [Y] Yes [N] No"
        if ($delbool -notin 'Y', 'y', 'N', 'n') {
            Write-Host "Please enter a valid response."
        }
    } while ($delbool -notin 'Y', 'y', 'N', 'n')

    if ($delbool -in 'Y', 'y') {
        $global:dadd = Read-Host "Enter email address for user delegation: "
    }
    else {
        Write-Host "No Delegation Address Entered, Mailbox Will Not Be Delegated"
    } 
}

# Update the display name and user profile
#function display_name {
#    $global:user.DisplayName = "x " + $global:user.DisplayName
#    Update-MgUser -UserId $global:user.Id -Displayname $global:user.Displayname
#    Write-Host "Display Name Updated" -ForegroundColor Green
#}
function display_name {
    try {
        $global:user.DisplayName = "x " + $global:user.DisplayName
        Update-MgUser -UserId $global:user.Id -Displayname $global:user.Displayname
        Write-Host "Display Name Updated" -ForegroundColor Green
    }
    catch {
        #Write-Host "An error occurred: $_" -ForegroundColor Red
        throw 
    }
}



# Password Generator Function
function Generate_Password {
    param(
        [int]$Length = 12,
        [int]$Count = 1
    )
    
    $UpperCaseChars = [char[]]([char]'A'..[char]'Z')
    $LowerCaseChars = [char[]]([char]'a'..[char]'z')
    $NumberChars = [char[]]([char]'0'..[char]'9')
    $SpecialChars = [char[]]('!', '@', '#', '$', '%', '^', '&', '*','|', ';', ':', ',', '.', '/', '?')
    
    for ($i = 1; $i -le $Count; $i++) {
        $PasswordChars = @()
        for ($j = 1; $j -le $Length; $j++) {
            switch (Get-Random -Minimum 1 -Maximum 5) {
                1 { $PasswordChars += $UpperCaseChars | Get-Random }
                2 { $PasswordChars += $LowerCaseChars | Get-Random }
                3 { $PasswordChars += $NumberChars | Get-Random }
                4 { $PasswordChars += $SpecialChars | Get-Random }
            }
        }
        $global:newpass = -join $PasswordChars
        Write-Output Password Changing To: $global:newpass
    }
}

# Set new password
function Set_Password {
    $global:newpass = ConvertTo-SecureString -String $global:newpass -AsPlainText -Force
    Update-MgUser -UserId $global:upn -PasswordProfile @{ Password = $global:newpass }
    Write-Host Password Changed -ForegroundColor Green
}
# See if we can or need to add ForceChangePasswordNextSignIn = $false or if it even matters ? defaults to true anyway 

# Disable Account / Block Sign In 
function disable_signon {
    Update-MgUser -UserID $global:upn -AccountEnabled:$false
    Write-Host "User sign-In Blocked" -ForegroundColor Green
}

# ------------------------- #
# Exchange Online Functions
# ------------------------- #

# connect to EOL 
# Might need to start script with multi-acct sign ins 
# Make this function like graphs where it checks for module
function Connect_EOL {
    Connect-ExchangeOnline -ShowBanner:$false
}

# Set Forwarding 
function mail_forward {
    if ($global:fadd) {
        Set-Mailbox $global:upn -ForwardingAddress $global:fadd
        Write-Host Mailbox Successfully forwarded to $global:fadd -ForegroundColor Green
    }
    else {
        Write-Host "No Forwarding Address Found, Mailbox Not Forwarded" -ForegroundColor Yellow 
    }
}

# Set Shared Mailbox 
function shared_mailbox {
    Set-Mailbox $global:upn -Type Shared 
    Write-Host "Mailbox Converted To Shared Mailbox Successfully" -ForegroundColor Green
}

# Delegate Access 
function delegate_mailbox {
    if ($global:dadd) {
        Add-MailboxPermission $global:upn -User $global:dadd -AccessRights FullAccess -InheritanceType all
        Write-Host Mailbox Successfully delegated to $global:dadd -ForegroundColor Green
    }
    else {
        Write-Host "No Delegation Account Found, Mailbox Not Delegated" -ForegroundColor Yellow
    }
}

# Remove Licenses 
function remove_licenses{   
    if ($global:user -eq $null) {
           Write-Host User $global:upn does not exist. Please check the user name. -ForegroundColor Red
                }
                else {
                    $Licenses = Get-MgUserLicenseDetail -UserId $global:upn
                    $Licenses = $Licenses.SkuID
                    $SkuPartNumber = @()
                    if ($Licenses.count -eq 0) {
                        Write-Host No license assigned to the user $global:upn. 
                    }
                    else {
                        foreach ($Temp in $Licenses) {
                            #$SkuPartNumber += $SkuIdHash[$Temp] - get this working to show which licenses are being removed 
                        }
                        $SkuPartNumber = $SkuPartNumber -join (",")
                        Write-Host Removing $SkuPartNumber license from $global:upn
                        Set-MgUserLicense -UserId $global:upn -RemoveLicenses @($Licenses) -AddLicenses @() | Out-Null
                        Write-Host Licenses Removed -ForegroundColor Green                        
                    }
                }
   }


function main() {
    Disconnect-MgGraph
    Connect_MgGraph
    user_info
    display_name
    Generate_Password
    Set_Password
    disable_signon
    Connect_EOL
    mail_forward
    shared_mailbox
    delegate_mailbox
    remove_licenses
}

. main 