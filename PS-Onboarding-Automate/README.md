# PS-Onboarding Automate

The scripts here will be used with Azure Automate (or other scheduler) to run onboarding processes. This is to be used in conjunction (after) [API-Driven-Inbound-Provisioning](../PS-API-Inbound-Provisioning/). 

While this was designed in a hybrid environment, considerations will be taken for most changes to occur in Entra with things like password writeback. This will ensure minimal changes when moving off of on-prem AD. 

The main function of this will be:
- Create a temporary password for the new user 2 days before start date 
- Send an email to their manager with this information 2 days before start date 

## managerEmailPassReset.ps1

This script is intended to be run locally with an interactive login for MsGraph

Logs are to be written locally

## File 2 

Same as < file above > but modified to run in an Azure Automation account using a system assigned managed idenity.

Logs are to be written to blob storage