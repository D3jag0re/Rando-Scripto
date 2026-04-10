# PS-UserProfile-Cleanup 

This script will delete any user profiles not logged into for 90 days. Due to the GPO setting being "all or nothing" we are using this script in order to allow exclusions. 

This sctipt will: 

- Delete profiles unused for 90 days
- Skip special/ system profile
- Exclude explicitly defined accounts
- Exclude members of one or more AD groups
- Write a log file 
- Have a dry-run option which will write to the log

## notes 

- AD group exclusion works by comparing profile ffolder name to the users `SamAccountName` . therefore might need special handling of things like renamed accounts etc.
- The script needs the Active Directory PowerShell module for AD group lookups. On workstations, that may not always be installed. If it is missing, the script will still run, but only the manually defined exclusions will apply.

