# This script will reset the password of the user, then send an email to their manager with their temporary password as well as start date details for the user. 

############################################################################
# Check if Microsoft Graph PowerShell module is installed, and if not, install it. 
# Requires Microsoft Graph PowerShell SDK
if (!(Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Output "Microsoft Graph PowerShell module is not installed. Installing now..."
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
} else {
    Write-Output "Microsoft Graph PowerShell module is already installed."
}


function Generate-Password {
    param(
        [int]$Length = 8,
        [int]$Count = 1
    )
    
    $UpperCaseChars = [char[]]([char]'A'..[char]'Z')
    $LowerCaseChars = [char[]]([char]'a'..[char]'z')
    $NumberChars = [char[]]([char]'1'..[char]'9')
    $SpecialChars = [char[]]('!', '@', '#', '$', '%')
    
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
Generate-Password 
#-Length 8 -Count 5



# Grabs all users in directory
# Connect To Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.Read.All", "UserAuthenticationMethod.ReadWrite.All", "Directory.AccessAsUser.All"
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype
$CheckDate = (Get-Date).adddays(-60)
$Employees | Where-Object {$CheckDate -as [datetime] -lt $_.EmployeeHireDate} | Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, employeeHireDate -AutoSize


######################################################################

# Will need "UserAuthenticationMethod.ReadWrite.All" if using temporaryAccessPass