# PS-Onboarding Automate

The scripts here will be used alongside Azure Automate (or other scheduler) to run onboarding processes. This is to be used in conjunction (after) api-driven inbound provisioning. 

While this was designed in a hybrid environment, considerations will be taken for most changes to occur in Entra with things like password writeback. This will ensure minimal changes when moving off of on-prem AD. 

The main function of this will be:
- Create a temporary password for the new user 2 days before start date 
- Send an email to their manager with this information 2 days before start date 