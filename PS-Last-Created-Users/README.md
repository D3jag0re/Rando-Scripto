# PS-Last-Created-Users

This script queries an on-Prem Domain Controller for the last 20 users created, returning name, email, and date created. It then exports this information to a log in a .txt file to the location specified. 

Best if run on an on-prem Domain Controller as Admin. 

## TO RUN 

Note: This assumes the script is being run on a Domain Controller. Must run Powershell in Admin.

1. Change the variables at the top of the script to suit your needs: 
    - $logPath

2. Run Script

3. Retrieve log from path specified. 