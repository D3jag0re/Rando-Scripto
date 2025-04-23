# PS-Populate-EmployeeID

This takes a .csv that has 'First Name' and 'Last Name' columns and queries AD in order to populate a "EmployeeID" column. 

Best if run on an on-prem Domain Controller as Admin. 

Due to this organizations email format (firstname.lastname@domain.com) it will use this to query.

## TO RUN 

Note: This assumes the .cvs's and script are being copied to and run on a Domain Controller. 

1. Change the three var at the top of the script to suit your needs: 
    - $inputCsvPath 
    - $outputCsvPath 
    - $defaultDomain 

2. Copy input .csv to path defined above 

3. Run Script 

