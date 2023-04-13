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
$newpass = [System.Web.Security.Membership]::GeneratePassword(12,1)
$newpass = ConvertTo-SecureString -String $newpass -AsPlainText -Force

# Set new password
Update-MgDUserPassword -UserId $upn -Password $newpass
