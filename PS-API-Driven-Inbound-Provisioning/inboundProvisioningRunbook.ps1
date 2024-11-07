# This is the runbook to be used in Azure Automation for api-driven inbound provisioning. 

######################
## Import & Connect ##
######################

# Import the modules
Import-module 'az.accounts'
Import-module 'Microsoft.Graph.Users'
Import-module 'Microsoft.Graph.Authentication'
Import-Module 'Microsoft.Graph.Users.Actions'

# Connect to Azure with the System Managed Identity
Connect-AzAccount -Identity

# Connect to Graph with the System Managed Identity
Connect-MgGraph -Identity 


###############
## Variables ##
###############

$path = pwd
$tempFolder = "$env:Temp" # Temp location to write new files to ?
$logTime = Get-Date -Format "yyyy-MM-dd"
$resourceGroup = "THCP-RG" # Reource group that hosts the storage account
$storageAccountName = "thcpuserlifecyclestorage" # Storage account name
$csvContainerName = "adp-hrcsv-export" # Container name where csv file is stored
$scriptContainerName = "provisioning-scripts" # Container name where scripts are stored 

$csvname = "testApiProvisioning.csv"



################
## Pull Files ##
################

$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName 

# Pull .csv
Get-AzStorageBlobContent -Container $csvContainerName -Blob $csvname -Context $storageContext -Destination $tempFolder

# Pull CSV2SCIM
Get-AzStorageBlobContent -Container $scriptContainerName -Blob "CSV2SCIM.ps1" -Context $storageContext -Destination $tempFolder

# Pull Attribute Mapping
Get-AzStorageBlobContent -Container $scriptContainerName -Blob "attributeMapping.psd1" -Context $storageContext -Destination $tempFolder


####################
## Create Payload ##
####################

cd $tempFolder

# Initialize AttributeMapping
$AttributeMapping = Import-PowerShellDataFile '.\AttributeMapping.psd1'

# Validate AttributeMapping 
.\CSV2SCIM.ps1 -Path ".\$($csvname)" -AttributeMapping $AttributeMapping -ValidateAttributeMapping

# Create Bulk Request
.\CSV2SCIM.ps1 -Path ".\$($csvname)" -AttributeMapping $AttributeMapping > BulkRequestPayload.json

# Verification for file pull and creation
#ls $tempFolder
#cat .\BulkRequestPayload.json

######################
## Pull Diagnostics ##
######################

# Verification for file pull and creation
#ls $tempFolder
#cat .\BulkRequestPayload.json

#######################
## POST Bulk Request ##
#######################

#Extract the access token from the AzAccount authentication context and use it to connect to Microsoft Graph
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token 
$uri = "https://graph.microsoft.com/v1.0/servicePrincipals/0bf65218-aed3-4d60-a2d9-2c2998e7ce05/synchronization/jobs/API2AD.90aa11d79f944dc8a78e13c091d34c1e.d234ab82-d9e9-415b-b7f2-7bb7ae24d8fb/bulkUpload"

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/scim+json"
}

$source = ".\BulkRequestPayload.json" 

# Invoke-RestMethod also works but will not return statusCode 
$response = Invoke-WebRequest -Uri $uri `
                              -Method POST `
                              -Headers $headers `
                              -InFile $source

# Output the response
Write-Output "Status Code: $($response.StatusCode)"





##############################################################################
##############################################################################

<#
# Test API call - grab user info
$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Retrieve user details by email
$userEmail = "user@example.com"  # Replace with actual user email
$response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/mathew.brinkworth@trilliumhcp.com" `
                              -Method GET `
                              -Headers $headers

# Output the response to verify
$response | Format-List

#>



#Invoke-MgGraphRequest -method GET -Uri "https://graph.microsoft.com/v1.0/users/" -OutputType PSObject
#Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/users/mathew.brinkworth@trilliumhcp.com'
#curl -X GET -H "Authorization: Bearer [accessTokenFromPreviousCommand]" https://graph.microsoft.com/v1.0/users/mathew.brinkworth@trilliumhcp.com

# POST
# Request headers - key:content-type value:application/scim+json
# Request body - BulkRequestPayload.json
# API Endpoint https://graph.microsoft.com/v1.0/servicePrincipals/0bf65218-aed3-4d60-a2d9-2c2998e7ce05/synchronization/jobs/API2AD.90aa11d79f944dc8a78e13c091d34c1e.d234ab82-d9e9-415b-b7f2-7bb7ae24d8fb/bulkUpload

