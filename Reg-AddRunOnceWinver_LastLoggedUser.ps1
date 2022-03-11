<#
    .Synopsis
       Add a RunOnce key to execute an application for the last logged on user, the user's SID is derived
       from the registry LogonUI key.
    .DESCRIPTION
       As the synopsis.
    .EXAMPLE
       Runs from the shell or inside a Task Sequence of SCCM/MECM.
    .LINK
       https://github.com/GeoSimos/MECM-SCCM-Scripts/edit/main/Reg-AddRunOnceWinver_LastLoggedUser.ps1
    .NOTES
      Written by George Simos (George_Simos@hotmail.com) 
      15/09/2021 Version 1.1
      User profiles are unloaded at logoff, changed the way we handle both cases (logged on/off user)
      20/09/2021 Version 1.2
      Moved the logged on Users option to an "Else" block.
      04/03/20221 Version 1.3
      Replaced hardcoded NB Domain with a variable.
      Added Sleep timers after Garbage Collection and registry unload to avoid potential profile corruptions.
    #>

# Setup the HKEY_USERS PSDrive for the registry manipulation.
If (!(Test-Path HKU:)) {
   (New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null)
}
# Variables setup
# Load the registry location of "LogonUI" details
$RegLastLoggeonUserValue = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
# Set the last part of the registry key to add the RunOnce action(s)
$RegUserRunOncePath = '\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
# Construct last logged on User's RunOnce registry path.
$RegLastLoggedonUserRunOnce = Join-Path -Path "HKU:\" -ChildPath ($RegLastLoggeonUserValue.LastLoggedOnUserSID + $RegUserRunOncePath)
# Set the default User Profiles location.
$RegUsersProfDefLocation = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name "ProfilesDirectory"
# Set the Domain's NETBIOS name
$RegLastLoggedonUserNBDomain = "KUJUIT"
# Set Users registry hive filename
$UserRegFilename = "NTUser.dat"
# Set the RunOnce actions to be populated, for multiple actions switch to hashtable.
$RegRunOnceActionName = "Launch_Winver_after_Win10_Upgrade"
$RegRunOnceActionValue = "Winver.exe"
# Set the RunOnce action for the last logged on user when the user's profile is unloaded (User not logged)
If (!(Test-Path $RegLastLoggedonUserRunOnce)) {
   # Load the last logged on User's registry hive in Registry HKEY_USERS tree.
   Reg load "HKU\$($RegLastLoggeonUserValue.LastLoggedOnUserSID)" "$($RegUsersProfDefLocation.ProfilesDirectory)$($RegLastLoggeonUserValue.LastLoggedOnSamUser.Replace('$RegLastLoggedonUserNBDomain',''))\$($UserRegFilename)"
   # Create the RunOnce action for the last logged on user.
   Set-ItemProperty -Path $RegLastLoggedonUserRunOnce -Name $RegRunOnceActionName -Value $RegRunOnceActionValue -ErrorAction Continue
   # Garbage collection to allow the unloading of the User's registry hive file.
   [gc]::Collect()
   [gc]::WaitForPendingFinalizers()
   Start-Sleep -Seconds 5
   # Unload the last logged on User's registry hive from Registry.
   Reg unload "HKU\$($RegLastLoggeonUserValue.LastLoggedOnUserSID)"
   Start-Sleep -Seconds 5
}
Else {
   # Set the RunOnce action for the last logged on user when the user's profile is already loaded (User logged).
   Set-ItemProperty -Path $RegLastLoggedonUserRunOnce -Name $RegRunOnceActionName -Value $RegRunOnceActionValue -ErrorAction Continue
}
# Remove HKU PSDrive
Remove-PSDrive -Name HKU
# Simplification trials
#Get-ItemProperty -Path ($HKU:)+($RegLastLoggeonUserValue.LastLoggedOnUserSID+$RegUserRunOncePath)
