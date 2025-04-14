# This script lists all folders and their contents in a structured format

Write-Host "Listing all folders and their contents:`n"

# Get all directories
$directories = Get-ChildItem -Path . -Recurse | Where-Object { $_.PSIsContainer -eq $true }

# Include the current directory
$directories = @((Get-Item .)) + $directories

# Loop through each directory
foreach ($dir in $directories) {
    # Get all files in the current directory
    $files = Get-ChildItem -Path $dir.FullName | Where-Object { $_.PSIsContainer -eq $false }

    if ($files.Count -gt 0) {
        # Print the folder name in brackets
        Write-Host "[$($dir.Name)]"

        # Print each file with indentation
        foreach ($file in $files) {
            Write-Host "`t$($file.Name)"
        }
    }
}

# Optional: Save to text file
$outputPath = ".\filename-output.txt"
$sb = New-Object System.Text.StringBuilder
$sb.AppendLine("Listing all folders and their contents:`n") | Out-Null

foreach ($dir in $directories) {
    $files = Get-ChildItem -Path $dir.FullName | Where-Object { $_.PSIsContainer -eq $false }
    if ($files.Count -gt 0) {
        $sb.AppendLine("[$($dir.Name)]") | Out-Null
        foreach ($file in $files) {
            $sb.AppendLine("`t$($file.Name)") | Out-Null
        }
    }
}

$sb.ToString() | Out-File -FilePath $outputPath

If (Test-Path $outputPath) {
    Write-Host "`nFiles have been saved to filename-output.txt"
}
