# PS AD Update  

Simple Script to parse over a csv (exported from ADP) and update on-prem AD as needed. 

Modify as needed.

Fields: 

|            Csv               | AD Attribute Name  |
| ---------------------------- | ------------------ |
| File Number                  | employeeID         |
| Legal First Name             | givenName          |
| Legal Last Name              | sn                 |
| Department Number            |                    |
| DEPARTMENT                   | department         | 
| Department Description       |                    | 
| Job Title Description        | title              | 
| Reports To Legal First Name  |                    |
| Reports to Legal Last Name   |                    |
| Hire Date                    |                    |  
| Position Status              |                    | 
| Work Contact: Work Email     | mail               |

- Manager format is CN=manager Name, OU=of manager, DC=trillium, DC=local
