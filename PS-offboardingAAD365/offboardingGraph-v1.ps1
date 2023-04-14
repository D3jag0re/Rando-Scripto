# Connect to MS Graph 
Connect-MgGraph -Scopes "Directory.ReadWrite.All"
# "Directory.AccessAsUser.All" needed for pw reset tho 
# Also "User.ReadWrite.All","Group.ReadWrite.All" for the groups 
# see ms docs for signing into more than one at once. get-credential (once) then connect while passing in those creds 

# Prompt For User Principal Name (email) / Forwarding (Y/N) / and Forwarding Adress
$upn = Read-Host "Enter the user principal name (UPN) of the user whose display name you want to update"
# Forwarding 
# Forwarding Adress $fadd

# Get the user object from Azure AD
$user = Get-MgUser -UserId $upn 

# Update the display name
$user.DisplayName = "x " + $user.DisplayName

# Update the user profile in Azure AD
Update-MgUser -UserId $user.Id -Displayname $user.Displayname

# create new password
function Generate-Password {
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
        $newpass = -join $PasswordChars
        Write-Output $newpass
    }
}

$newpass = ConvertTo-SecureString -String $newpass -AsPlainText -Force

# Set new password
Update-MgUser -UserId $upn -PasswordProfile @{ Password = $newpass }
# See if we can or need to add ForceChangePasswordNextSignIn = $false or if it even matters ? defaults to true anyway 

# Disable Account / Block Sign In 
Update-MgUser -UserID $upn -AccountEnabled:$false

# ------------------------------------------------------------------------------------
# Exchange Online Commands 
# Might need to start script with multi-acct sign ins 

Connect-ExchangeOnline

# Set Forwarding 
Set-Mailbox $upn -ForwardingAddress $fadd 

# Set Shared Mailbox 
Set-Mailbox $upn -Type Shared

# Delegate Access 
Add-MailboxPermission $upn -User "Mail Recipient" -AccessRights FullAccess -InheritanceType all

# -----------------------------------------------------------------------------------------

# Remove Licenses 
# See "manageM365licenses" for function (Action  8)

