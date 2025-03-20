# This is the runbook to be used in Azure Automation for api-driven inbound provisioning. 

######################
## Import & Connect ##
######################

# Import the modules
Import-module 'az.accounts'
Import-module 'Microsoft.Graph.Users'
Import-module 'Microsoft.Graph.Authentication'
Import-Module 'Microsoft.Graph.Users.Actions'
Import-Module 'Microsoft.Graph.Applications' 
Import-Module 'Microsoft.Graph.Reports'

# Connect to Azure with the System Managed Identity
Connect-AzAccount -Identity

# Connect to Graph with the System Managed Identity
Connect-MgGraph -Identity 


###############
## Variables ##
###############

$TenantId = (Get-AzContext).Tenant.Id # Curent Tenant ID
Write-Output "Tenant ID: $TenantId"
$Context = Get-MgContext
$ClientId = $Context.ClientId
Write-Output "Client ID: $ClientId"
$tempFolder = "$env:Temp" # Temp location to write new files to
$storageAccountName = "thcpuserlifecyclestorage" # Storage account name
$csvContainerName = "adp-hrcsv-export" # Container name where csv file is stored
$scriptContainerName = "provisioning-scripts" # Container name where scripts are stored 

$csvname = "IT_Headcount_Report.csv"



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

Set-Location $tempFolder

# Initialize AttributeMapping
$AttributeMapping = Import-PowerShellDataFile '.\AttributeMapping.psd1'

# Validate AttributeMapping 
#.\CSV2SCIM.ps1 -Path ".\$($csvname)" -AttributeMapping $AttributeMapping -ValidateAttributeMapping

# Create and Sent Bulk Request
.\CSV2SCIM.ps1 -Path ".\$($csvname)" -AttributeMapping $AttributeMapping -ClientId $ClientId -TenantId $TenantId -ServicePrincipalId [Service_Principal_of_Provisioning_app * Replace with ID]

# Create Bulk Request
#.\CSV2SCIM.ps1 -Path ".\$($csvname)" -AttributeMapping $AttributeMapping > BulkRequestPayload.json


#######################
## POST Bulk Request ##
#######################

# This only applies when users are < 50. Otherwise it fails as the bulkreport is split into multiple JSON objects.

<# 

#Extract the access token from the AzAccount authentication context and use it to connect to Microsoft Graph
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token 
$uri = "https://graph.microsoft.com/v1.0/servicePrincipals/0bf65218-aed3-4d60-a2d9-2c2998e7ce05/synchronization/jobs/API2AD.90aa11d79f944dc8a78e13c091d34c1e.d234ab82-d9e9-415b-b7f2-7bb7ae24d8fb/bulkUpload"

$headers = @{
    Authorization = "Bearer $token"
    'Content-Type' = "application/scim+json"
}

$source = ".\BulkRequestPayload.json" 

# Invoke-RestMethod also works but will not return statusCode 
$response = Invoke-WebRequest -Uri $uri `
                              -Method POST `
                              -Headers $headers `
                              -InFile $source

# Output the response
Write-Output "Status Code: $($response.StatusCode)"

#>
#######################
##    Rename File    ##
#######################

# Get the current date in MMDDYYYY format
$timestamp = Get-Date -Format "MMddyyyy"

# Define the new filename with the timestamp
$newCsvName = [System.IO.Path]::GetFileNameWithoutExtension($csvname) + "_$timestamp" + [System.IO.Path]::GetExtension($csvname)

# Upload the file with the new name
Set-AzStorageBlobContent -File "$tempFolder\$csvname" `
                         -Container $csvContainerName `
                         -Blob $newCsvName `
                         -Context $storageContext `
                         -Force

# Optionally delete the old file from the blob
Remove-AzStorageBlob -Container $csvContainerName `
                     -Blob $csvname `
                     -Context $storageContext `
                     -Force

Write-Output "File renamed in blob storage: $newCsvName"


##############################################################################
##############################################################################