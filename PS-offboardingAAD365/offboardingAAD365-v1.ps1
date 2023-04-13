# Connect to Azure AD
Connect-AzureAD

# Prompt for user principal name (UPN)
$upn = Read-Host "Enter the user principal name (UPN) of the user whose display name you want to update"

# Get the user object from Azure AD
$user = Get-AzureADUser -ObjectId $upn

# Update the display name
$user.DisplayName = "x " + $user.DisplayName

# Update the user profile in Azure AD
Set-AzureADUser -ObjectId $user.ObjectId -DisplayName $user.DisplayName

#or set something like $newDisplayName and set that in the update field???

# create new password
$newpass = [System.Web.Security.Membership]::GeneratePassword(12,1)
$newpass = ConvertTo-SecureString -String $newpass -AsPlainText -Force

# Set new password
Set-AzureADUserPassword -ObjectId $upn -Password $newpass 

# Block Sign in
Set-AzureADUser -ObjectID $upn -AccountEnabled $false


# Disconnect from Azure AD
# Disconnect-AzureAD

# Connect To EOL 
Connect-ExchangeOnline

#Set Forwarding 
Set-Mailbox $upn -ForwardingAddress "<email_address>"
# Put in way to get prompt for this (Y/N then enter forwarding adress...check if adress exists in tenant)


# Remove Licenses (Requires MS Graph module)

