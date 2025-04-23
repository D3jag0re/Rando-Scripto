# PS-Populate-EmployeeID

This takes a .csv that has 'First Name' and 'Last Name' columns and queries AD in order to populate a "EmployeeID" column. 

Best if run on an on-prem Domain Controller as Admin. 

Due to this organizations email format (firstname.lastname@domain.com) it will use this to query.