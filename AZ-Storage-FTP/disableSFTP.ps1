# Identity needs 'Microsoft.Storage/storageAccounts/write'
$resourceGroupName = "<resource-group>"
$storageAccountName = "<storage-account>"

Connect-AZAccount -Identity
Set-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -EnableSftp $false