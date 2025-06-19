<#
.SYNOPSIS
Checks for the installation of specified Appx applications from a CSV input, for use as a ConfigMgr configuration baseline compliance script.

.DESCRIPTION
Reads a CSV file containing Appx application names or package family names, checks if each is installed for the current user. Intended for use as a compliance script in a ConfigMgr configuration baseline.

.PARAMETER CsvPath
Path to the CSV file containing Appx application names or package family names. The CSV should have a column named 'AppxName'.

.EXAMPLE
.\Check-Appx-to-Remove.ps1 -CsvPath "C:\Scripts\AppxList.csv"

.NOTES
Author: George Simos <George_Simos@hotmail.com>
Version: 1.0
Created: 20-6-2025
Modified: 20-6-2025

# To generate a list of installed Appx applications and export to CSV, run:
# Get-AppxPackage | Select-Object -ExpandProperty Name | Sort-Object | Export-Csv -Path "C:\Scripts\AppxList.csv" -NoTypeInformation

# Sample CSV for Appx applications to check
# Save this as AppxList.csv

AppxName
Microsoft.ZuneMusic
Microsoft.WindowsCamera
Microsoft.XboxApp
Microsoft.SkypeApp

#>
param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

# Import the list of Appx names from the CSV
try {
    $appxList = Import-Csv -Path $CsvPath
} catch {
    Write-Error "Failed to import CSV file at path: $CsvPath"
    exit 1
}

if (-not $appxList -or -not $appxList.AppxName) {
    Write-Error "CSV file must contain a column named 'AppxName' with at least one entry."
    exit 1
}

# Track compliance
$nonCompliantApps = @()

foreach ($app in $appxList) {
    $appName = $app.AppxName
    if ([string]::IsNullOrWhiteSpace($appName)) { 
        continue 
    }

    $found = Get-AppxPackage -Name $appName -ErrorAction SilentlyContinue
    if ($found) {
        $nonCompliantApps += $appName
    }
}

if ($nonCompliantApps.Count -eq 0) {
    Write-Output "Compliant: None of the specified Appx applications are installed."
    exit 0
} else {
    Write-Output "NonCompliant: The following Appx applications are installed:`n$($nonCompliantApps -join "`n")"
    exit 1
}
