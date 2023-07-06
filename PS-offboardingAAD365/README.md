# PS Offboarding Script for AzureAD (AAD) / 365 

- [X] Put x in front of display name 
- [X] Reset Password 
- [X] Block sign in 
- [X] Set Email forwarding (if req)
- [X] Release Licenses 
- [X] Convert to Shared Mailbox
- [X] Delegate Access to mailbozx (if req) 
- [ ] Put all user input and connections at beginning (Half. conditions yes, connections no)
- [X] Conditional Mail forwarding and Delegation 
- [X] Visual Feedback as script executes 


## Errors 

Currently Will throw the system error if the upn of the user is not found.\
It finishes the first function but then stops once the error is thrown in second function.\
Get it to stop asking for inputs after first error is thrown.

## Notes 

Use Graph and EOL modules.  
Look into ways to have a SSO for both services which require connection (cert based auth for EOL?) 

Future: 

Be able to pass through upn and forward / delegation info in command line\
Eventually would like to be able to call on just some of them (make all functions) with more variables to pass through\
Bulk Operations

## V2+:

 - [ ] Write output to file in Blob Storage for Tracking 
 - [ ] Create "Undo" command ? Would have to store current config in order to revert 
 - [ ] Remove User from all groups (Lots of issues with Graph Permissions here)
 - [ ] Connect with Freshdesk API to fully automate
