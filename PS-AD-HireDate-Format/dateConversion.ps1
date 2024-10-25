# This will convert time format from a .csv from dd/mm/yyyy format to the time format needed for Entra's "employeeHireDate" attribute which is  “yyyyMMddHHmmss.fZ“
# For Example. 01/12/2022 at 8:00am becomes 20221201080000.0Z 

$inputPath = "C:\Path\To\File.csv"
$outputPath = "C:\Path\To\Fileconverted.csv"

# Load the CSV file
$csv = Import-Csv -Path $inputPath


# Process each row to update "convertedDate" in the required format
$csv | ForEach-Object {
    # Check if "Start Date" exists and is not empty
    if ($_."Start Date") {
        # Split the date string by '/' and rearrange to yyyyMMdd
        $dateParts = $_."Start Date" -split '/'
        $formattedDate = $dateParts[2] + $dateParts[1] + $dateParts[0] + "080000.0Z"
        
        # Assign the formatted date to the "convertedDate" column
        $_."convertedDate" = $formattedDate
        
        # Output each row to verify
        Write-Host "Processing row: $($_ | Out-String)"
    } else {
        Write-Host "Missing 'Start Date' for row. Skipping this row."
    }
}

# Export the modified data to a new CSV file
$csv | Export-Csv -Path $outputPath -NoTypeInformation -Force

Write-Host "CSV processing complete. Output saved to $outputPath"