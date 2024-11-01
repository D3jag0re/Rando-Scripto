# Random dump for testing commands 

Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

[datetime]$Date = (Get-Date).adddays(-60)
$Users = Get-MgGroupMember -GroupId 5ce5dfa8-a319-40e7-a77a-92a1e5eee77f -All
$Users.Count
$UsersCreatedDate = $Users.ForEach{
    Get-MgUser -UserId $_.Id | Select-Object -Property Id,UserPrincipalName,JobTitle,CreatedDateTime,EmployeeHireDate
}

$UsersCreatedDate | Where-Object {($_.EmployeeHireDate -gt $Date)} 
$Date

#####This would be great if they allowed filters for server side filtering 
Get-MgUser -Filter "EmployeeHireDate ge $([datetime]::UtcNow.AddYears(-1).ToString("s"))Z" | Format-Table -AutoSize Id, UserPrincipalName, CreatedDateTime, EmployeeHireDate

######

[array]$Employees = Get-MgUser -All -filter "userType eq 'Member' and EmployeeId ge ' '" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype
$CheckDate = (Get-Date).adddays(-60)
$Employees | Where-Object {$CheckDate -as [datetime] -lt $_.EmployeeHireDate} | Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, employeeHireDate -AutoSize

############

$Users = Get-MgUser -filter "userType eq 'Member' and EmployeeId ge ' '" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype


############

#Invoking directly grabs it while the above does not.  
$response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/users?`$filter=displayName eq 'Ronald Smith'&`$select=displayName,mail,employeeHireDate"

# Display the response
$response.value | Select-Object displayName, mail, employeeHireDate


################################

#Also works...
$MgUser = Get-MgUser -UserId "username@domain.com" -Property employeeHireDate,employeeLeaveDateTime,EmployeeOrgData,userType
 
$MgUser.EmployeeHireDate
$MgUser.EmployeeLeaveDateTime
$MgUser.EmployeeOrgData.CostCenter
$MgUser.EmployeeOrgData.Division

#$MgUser.EmployeehireDate formats as Friday, November 1, 2024 8:00:00 AM
#Uri returns 11/1/2024 8:00:00 AM


############################

#Test password change with force next login.
$UserId = "username@domain.com"

$params = @{
    passwordProfile = @{
        forceChangePasswordNextSignIn = $true
        password                      = "GH56#theone" 
    }
}

Update-MgUser -UserId $userId -BodyParameter $params

#######################
# Grab all employees with start dates in last 60 days .\Rando-Scripto[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype
$CheckDate = (Get-Date).adddays(-60)
$Employees | Where-Object {$CheckDate -as [datetime] -lt $_.EmployeeHireDate} | Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, employeeHireDate -AutoSize

#######################
# Same as above but 60 days ahead
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype
$CheckDate = (Get-Date).AddDays(60)
$Employees | Where-Object {$_.EmployeeHireDate -as [datetime] -lt $CheckDate -and $_.EmployeeHireDate -as [datetime] -gt (Get-Date)} | Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, employeeHireDate -AutoSize

#######################
# Same as above but exactly 3 days
[array]$Employees = Get-MgUser -All -filter "userType eq 'Member'" -Property Id, displayname, userprincipalname, employeeid, employeehiredate, employeetype
$CheckDate = (Get-Date).AddDays(3)
$Employees | Where-Object {($_.EmployeeHireDate -as [datetime]).Date -eq $CheckDate.Date} | Sort-Object {$_.EmployeeHireDate -as [datetime]} -Descending | Format-Table DisplayName, userPrincipalName, employeeHireDate -AutoSize

#######################
# Send Email Test
Import-Module Microsoft.Graph.Users.Actions

$params = @{
	message = @{
		subject = "Meet for lunch?"
		body = @{
			contentType = "Text"
			content = "The new cafeteria is open."
		}
		toRecipients = @(
			@{
				emailAddress = @{
					address = "username@domain.com"
				}
			}
		)
	}
	saveToSentItems = "false"
}

# A UPN can also be used as -UserId.
Send-MgUserMail -UserId $userId -BodyParameter $params