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
Version: 1.1
Created: 20-06-2025
Modified: 13-08-2025
-Added CMTrace logging functionality and implemented logging for each AppxPackage removal and errors.
-Added default value for CSV Parameter as it can't be passed in a ConfigMgr Configuration Baseline Item.
-Removed exit commands as they are not suitable for use in a ConfigMgr configuration baseline compliance script.
-Replaced CSV import with an internal list of Appx packages to remove. ConfigMgr Configuration Baselines do not support accompanying files with scripts in CI-CBs.
Modified: 01-09-2025
-Added Microsoft Teams Personal for Windows 11.
Modified: 03-09-2025
-Fixed wrong month format in CMTrace logging function.

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

# Function to write logs in CMTrace format
function Write-CMTraceLog {
    param (
        [string]$Message,
        [string]$Component = "AppxDetection",
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Severity = "Info",
        [string]$LogPath = "$env:Windir\Logs\Windows-AppxRemoval.log"
    )

    $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss.fff"
    $threadId = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $entry = "$timestamp $threadId $Component $Severity $Message"
    Add-Content -Path $LogPath -Value $entry
}

# Internal list of Appx packages to remove
$AppxPackagesToRemove = @(
    @{ AppxName = "Clipchamp.Clipchamp" },
    @{ AppxName = "Microsoft.549981C3F5F10" },
    @{ AppxName = "Microsoft.Copilot" },
    @{ AppxName = "Microsoft.GamingApp" },
    @{ AppxName = "Microsoft.GetHelp" },
    @{ AppxName = "Microsoft.Getstarted" },
    @{ AppxName = "Microsoft.MicrosoftOfficeHub" },
    @{ AppxName = "Microsoft.MicrosoftSolitaireCollection" },
    @{ AppxName = "Microsoft.MicrosoftStickyNotes" },
    @{ AppxName = "Microsoft.MSPaint" },
    @{ AppxName = "Microsoft.OutlookForWindows" },
    @{ AppxName = "Microsoft.People" },
    @{ AppxName = "Microsoft.StorePurchaseApp" },
    @{ AppxName = "MicrosoftTeams" },
    @{ AppxName = "Microsoft.windowscommunicationsapps" },
    @{ AppxName = "Microsoft.WindowsFeedbackHub" },
    @{ AppxName = "Microsoft.Xbox.TCUI" },
    @{ AppxName = "Microsoft.XboxGameOverlay" },
    @{ AppxName = "Microsoft.XboxGamingOverlay" },
    @{ AppxName = "Microsoft.XboxIdentityProvider" },
    @{ AppxName = "Microsoft.XboxSpeechToTextOverlay" },
    @{ AppxName = "Microsoft.YourPhone" },
    @{ AppxName = "Microsoft.ZuneVideo" }
) 

# Parameters definition block
# $csvPath = ".\AppxList.csv"
# param (
#     [Parameter(Mandatory = $true)]
#     [string]$csvPath = $csvDefaultFile
# )

<# # Import the list of Appx names from the CSV
try {
    Write-CMTraceLog -Message "Attempting to import CSV file from path: $csvPath" -Severity "Info"
    $appxList = Import-Csv -Path $csvPath
    Write-CMTraceLog -Message "Successfully imported CSV file from path: $csvPath" -Severity "Info"
}
catch {
    Write-CMTraceLog -Message "Failed to import CSV file at path: $csvPath. Error: $($_.Exception.Message)" -Severity "Error"
    Write-Output "NonCompliant: Failed to import CSV file at path: $csvPath"
    return
} #>

<# # Validate the CSV content
if (-not $appxList -or -not $appxList.AppxName) {
    Write-CMTraceLog -Message "CSV file validation failed. The file must contain a column named 'AppxName' with at least one entry." -Severity "Error"
    Write-Output "NonCompliant: CSV file must contain a column named 'AppxName' with at least one entry."
    return
} #>

# Write-CMTraceLog -Message "CSV file validation passed. Proceeding with Appx package checks." -Severity "Info"
# Track compliance
$nonCompliantApps = @()

foreach ($app in $AppxPackagesToRemove) {
    $appName = $app.AppxName
    if ([string]::IsNullOrWhiteSpace($appName)) { 
        Write-CMTraceLog -Message "Skipping empty or invalid AppxName entry in list." -Severity "Warning"
        continue 
    }
    # Check if the Appx package is installed
    $found = Get-AppxPackage -Name $appName -AllUsers -ErrorAction SilentlyContinue
    if ($found) {
        Write-CMTraceLog -Message "AppxPackage found: $appName" -Severity "Info"
        $nonCompliantApps += $appName
    }
    else {
        Write-CMTraceLog -Message "AppxPackage not found: $appName" -Severity "Info"
    }
}

# Output compliance results
if ($nonCompliantApps.Count -eq 0) {
    Write-CMTraceLog -Message "Compliance check passed. No specified Appx packages are installed." -Severity "Info"
    Write-Output "Compliant"
}
else {
    Write-CMTraceLog -Message "Compliance check failed. The following Appx packages are installed: $($nonCompliantApps -join ', ')" -Severity "Error"
    Write-Output "NonCompliant: The following Appx applications are installed:`n$($nonCompliantApps -join "`n")"
}