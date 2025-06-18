# Paths to the CSV files
$queryCsvPath = "Query Result.csv"
$deviceCsvPath = "DeviceList.csv"
$outputCsvPath = "Updated_DeviceList.csv"

# Import CSVs
$queryResults = Import-Csv $queryCsvPath
$deviceList = Import-Csv $deviceCsvPath

# Create a hashtable for quick lookup of Start/End by Serial from Query Result
$lookup = @{}
foreach ($row in $queryResults) {
    $lookup[$row.Serial] = @{ Start = $row.Start; End = $row.End }
}

# Update DeviceList where Serial matches
foreach ($device in $deviceList) {
    if ($lookup.ContainsKey($device.Serial)) {
        $device.Start = $lookup[$device.Serial].Start
        $device.End   = $lookup[$device.Serial].End
    }
}

# Export updated DeviceList
$deviceList | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Output "DeviceList updated and saved to $outputCsvPath"
