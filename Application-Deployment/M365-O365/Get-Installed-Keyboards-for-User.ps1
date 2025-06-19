<#
.SYNOPSIS
    Lists installed keyboard layouts for the current user, excluding English, German, and French.

.DESCRIPTION
    This script reads the current user's installed keyboard layouts from the registry,
    maps them to language tags, and outputs the list excluding English, German, and French.
    Useful for determining which Microsoft 365 proofing tools to install.

.NOTES
    File Name : Get-Installed-Keyboards-for-User.ps1
    Author: George Simos <George_Simos@hotmail.com>
    Date: 20-6-2025
    Last Modified: 20-6-2025
    Version: 1.0
    Requires  : PowerShell 5.1 or later
#>

# Get-Installed-Keyboards-for-User.ps1
# Lists installed keyboard layouts for the current user, excluding English, German, and French.

$regPath = "HKCU:\Keyboard Layout\Preload"
$keyboards = Get-ItemProperty -Path $regPath | Select-Object -Property * | ForEach-Object {
    $_.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | ForEach-Object { $_.Value }
}

# Map keyboard layout IDs to language tags
function Get-LanguageTagFromKLID($klid) {
    $culture = [System.Globalization.CultureInfo]::GetCultureInfo([int]("0x$klid"))
    return $culture.Name
}

$excludeLangs = @(
    'en',      # English
    'de',      # German
    'fr'       # French
)

$keyboardLanguages = $keyboards | ForEach-Object { Get-LanguageTagFromKLID $_ } | Sort-Object -Unique

Write-Output "Installed keyboard layouts for user (excluding English, German, French):"
$keyboardLanguages | Where-Object {
    $lang = $_.Split('-')[0]
    $excludeLangs -notcontains $lang
} | ForEach-Object { Write-Output $_ }