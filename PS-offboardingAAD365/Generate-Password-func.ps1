$uppercase = [char[]]('A'..'Z')
$lowercase = [char[]]('a'..'z')
$numbers = [char[]]('0'..'9')
$specialChars = [char[]]('!','@','#','$','%','^','&','*','(',')','-','_','=','+','[',']','{','}',';',':','<','>',',','.','?','/','\','|','~','`')

$validChars = $uppercase + $lowercase + $numbers + $specialChars
$password = ''
$rand = New-Object System.Random

while ($password.Length -lt 12) {
    $nextChar = $validChars[$rand.Next(0, $validChars.Length)]
    if ($nextChar -in $uppercase) {
        if (-not $uppercaseUsed) {
            $uppercaseUsed = $true
        }
    } elseif ($nextChar -in $lowercase) {
        if (-not $lowercaseUsed) {
            $lowercaseUsed = $true
        }
    } elseif ($nextChar -in $numbers) {
        if (-not $numberUsed) {
            $numberUsed = $true
        }
    } elseif ($nextChar -in $specialChars) {
        if (-not $specialCharUsed) {
            $specialCharUsed = $true
        }
    }

    $password += $nextChar
}

if (-not $uppercaseUsed -or -not $lowercaseUsed -or -not $numberUsed -or -not $specialCharUsed) {
    $password = $password.Remove($rand.Next(0, $password.Length), 1)
    $password += $validChars[$rand.Next(0, $validChars.Length)]
}

Write-Output $password


