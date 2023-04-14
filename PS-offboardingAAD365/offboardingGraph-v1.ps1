# Connect to MS Graph 
Connect-MgGraph -Scopes "Directory.ReadWrite.All"

# Prompt For User Principal Name (email)
$upn = Read-Host "Enter the user principal name (UPN) of the user whose display name you want to update"

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
Update-MgDUserPassword -UserId $upn -Password $newpass

