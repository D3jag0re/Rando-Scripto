# Calculate the cutoff date (6 months ago from today)
$cutoffDate = (Get-Date).AddMonths(-6)

# Query Active Directory for users whose LastLogonDate is older than the cutoff date
Get-ADUser -Filter {LastLogonDate -lt $cutoffDate} -Properties LastLogonDate | 
    Select-Object Name, SamAccountName, LastLogonDate |
    Sort-Object LastLogonDate