# This is the runbook to be used in Azure Automation for api-driven inbound provisioning. 

################
## Pull Files ##
################
$path = pwd
$tempFolder = "$env:Temp" # Temp location to write new files to ?
$logTime = Get-Date -Format "yyyy-MM-dd"
$resourceGroup = "<your_resource_group>" # Reource group that hosts the storage account
$storageAccountName = "<your_storage_account>" # Storage account name
$csvContainerName = "<your_container>" # Container name where csv file is stored
$scriptContainerName = "<your_container_name>" # Container name where scripts are stored 


####################
## Create Payload ##
####################

# Initialize AttributeMapping
$AttributeMapping = Import-PowerShellDataFile '..\Samples\AttributeMapping.psd1'

# Validate AttributeMapping 
.\CSV2SCIM.ps1 -Path '..\Samples\csv-with-2-records.csv' -AttributeMapping $AttributeMapping -ValidateAttributeMapping

# Create Bulk Request
.\CSV2SCIM.ps1 -Path '..\Samples\csv-with-2-records.csv' -AttributeMapping $AttributeMapping > BulkRequestPayload.json

#####################
## Post using cURL ##
#####################



