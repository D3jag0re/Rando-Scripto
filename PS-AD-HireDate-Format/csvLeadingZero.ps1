# Add leading zeros to single digit time entries to make correct dd/mm/yyyy format
# Note: If you open in Excel it won't show the leading zero. Open in other text editor to validate

$inputPath = "C:\Path\To\report8.csv"
$outputPath = "C:\Path\To\report8temp.csv"

# Load the CSV file
$csv = Import-Csv -Path $inputPath

# Check if data was loaded correctly
if (!$csv) {
    Write-Host "Error: Failed to load data from path\to\your\file.csv"
    return
}

# Process each row to add leading zeros to single-digit days or months
$csv | ForEach-Object {
    # Check if "hire date" field exists and has a value
    if ($_."hire date") {
        $hireDate = $_."hire date"
        Write-Host "Original Hire Date: $hireDate"

        # Split the date into day, month, and year
        $day, $month, $year = $hireDate -split '/'

        # Add leading zeros to day and month if necessary
        $day = $day.PadLeft(2, '0')
        $month = $month.PadLeft(2, '0')

        # Create the "start date" column with the standardized hire date
        $_."start date" = "$day/$month/$year"
        Write-Host "Standardized Start Date: $($_."start date")"  # Debug output
    } else {
        Write-Host "Warning: 'hire date' field is empty or missing for this row"
        $_."start date" = ""  # Leave start date blank if hire date is missing
    }
}

# Export the modified CSV data
$csv | Export-Csv -Path $outputPath -NoTypeInformation -Force

Write-Host "Hire dates standardized. Output saved to $outputPath"
