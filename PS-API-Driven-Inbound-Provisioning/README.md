# API-Driven-Inbound-Provisioning with Powershell 

These files are for testing this feature in a hybrid AD environment. See here for details : https://github.com/AzureAD/entra-id-inbound-provisioning/tree/main/PowerShell

$AttributeMapping = Import-PowerShellDataFile '.\attributeMapping.psd1'
.\CSV2SCIM.ps1 -Path $Path -AttributeMapping $AttributeMapping -ValidateAttributeMap
.\CSV2SCIM.ps1 -Path $Path -AttributeMapping $AttributeMapping > BulkRequestPayload.json

Manually upload (for testing)

- Then you can go to graph explorer:
- POST
- Put in your provisioning API endpoint
- Set request headers Key:Value > Content-Type:application/scim+json
- Paste payload.json into the request body
- Run query