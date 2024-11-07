# API-Driven-Inbound-Provisioning with Powershell 

These files are for testing this feature in a hybrid AD environment. See here for details : https://github.com/AzureAD/entra-id-inbound-provisioning/tree/main/PowerShell

## Manual

$AttributeMapping = Import-PowerShellDataFile '.\attributeMapping.psd1' \
.\CSV2SCIM.ps1 -Path $Path -AttributeMapping $AttributeMapping -ValidateAttributeMap \
.\CSV2SCIM.ps1 -Path $Path -AttributeMapping $AttributeMapping > BulkRequestPayload.json

Manually upload (for testing)

- Then you can go to graph explorer:
- POST
- Put in your provisioning API endpoint
- Set request headers Key:Value > Content-Type:application/scim+json
- Paste payload.json into the request body
- Run query

## Azure Automate 

Use inboundProvisioningRunbook.ps1 as the runbook. 

When running from an Azure Automate account using a system assigned managed identity, you will need to assign graph permissions:
 - SynchronizationData-User.Upload (For sending the bulkupload)

 v1 Uses blob storage for all files, whereas v2 will feature a git integration for everything other than the csv