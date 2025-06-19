# Hide PowerShell Console window.
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

# Create main form.
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '600,400'
$Form.text = "Office 365 Language Pack Installer"
$Form.TopLevel = $true
$form.startposition = 'centerscreen'
$form.FormBorderStyle = 'Fixed3D'
$form.Icon = [System.Drawing.SystemIcons]::WinLogo

# Add combo box. Use array for data source.
$SelectLanguage = New-Object system.Windows.Forms.ComboBox
$SelectLanguage.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$SelectLanguage.text = "Select Language"
$SelectLanguage.width = 280
$SelectLanguage.height = 20
$items=[collections.arraylist]@(
    [pscustomobject]@{Name='Chinese Language Pack';Value='zh-cn'}
    [pscustomobject]@{Name='Czech Language Pack';Value='cs-cz'}
    [pscustomobject]@{Name='Danish Language Pack';Value='da-dk'}
    [pscustomobject]@{Name='Estonian Language Pack';Value='et-ee'}
    [pscustomobject]@{Name='Finish Language Pack';Value='fi-fi'}
    [pscustomobject]@{Name='French Language Pack';Value='fr-fr'}
    [pscustomobject]@{Name='German Language Pack';Value='de-de'}
    [pscustomobject]@{Name='Greek Language Pack';Value='el-gr'}
    [pscustomobject]@{Name='Hungarian Language Pack';Value='hu-hu'}
    [pscustomobject]@{Name='Italian Language Pack';Value='it-it'}
    [pscustomobject]@{Name='Korean Language Pack';Value='ko-kr'}
    [pscustomobject]@{Name='Latvian Language Pack';Value='lv-lv'}
    [pscustomobject]@{Name='Lithuanian Language Pack';Value='lt-lt'}
    [pscustomobject]@{Name='Nederlands Language Pack';Value='nl-nl'}
    [pscustomobject]@{Name='Norwegian Language Pack';Value='nb-no'}
    [pscustomobject]@{Name='Polish Language Pack';Value='pl-pl'}
    [pscustomobject]@{Name='Russian Language Pack';Value='ru-ru'}
    [pscustomobject]@{Name='Slovak Language Pack';Value='sk-sk'}
    [pscustomobject]@{Name='Spanish Language Pack';Value='es-es'}
    [pscustomobject]@{Name='Swedish Language Pack';Value='sv-se'}
    [pscustomobject]@{Name='Turkish Language Pack';Value='tr-tr'}
)
$SelectLanguage.DataSource=$items
$SelectLanguage.DisplayMember='Name'
$SelectLanguage.location = New-Object System.Drawing.Point(150,40)
$SelectLanguage.Font = 'Microsoft Sans Serif,10'

# Add button with click event. Based on registry presence, set $addrem variable. Export xml and overwrite if it already exists.
# Start-Process with -Wait so that the forms window will not be selectable while installation is running.
# use $this.Text to update the button once installation finishes.
$close = New-Object system.Windows.Forms.Button
$close.text = "Install / Uninstall"
$close.width = 120
$close.height = 30
$close.location = New-Object System.Drawing.Point(230,80)
$close.Font = 'Microsoft Sans Serif,10'
$close.Add_Click({
$option = $SelectLanguage.SelectedItem.value
$optionpath = 'O365ProPlusRetail - '+$option
$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
if(Test-Path $(join-path $regpath $optionpath)) {
$addrem = 'Remove'
} else {
$addrem = 'Add'
}

$xmltemplate = @"
<Configuration>
<$addrem OfficeClientEdition="64">
<Product ID="LanguagePack">
<Language ID="$option" />
</Product>
</$addrem>
     <Display Level="Full" AcceptEULA="True" />
</Configuration>
"@
$xmltemplate | Out-File -FilePath $("" + $pwd + "\" + "configure.xml")
Start-Process -Wait -NoNewWindow "$pwd\setup.exe" -ArgumentList "/configure $pwd\configure.xml"
$this.Text = if(Test-Path $(join-path $regpath $optionpath)) {'Remove'} else {'Add'}
}
)

# Update button text when a value in combobox is selected, based on installation status.
$SelectLanguage_SelectedIndexChanged=
{$option = $SelectLanguage.SelectedItem.value
$optionpath = 'O365ProPlusRetail - '+$option
$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
if(Test-Path $(join-path $regpath $optionpath)) {$close.text = 'Remove'} else {$close.text = 'Add'}
}
$SelectLanguage.add_SelectedIndexChanged($SelectLanguage_SelectedIndexChanged)

# Add informational text for the user & hope they read it :)
$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline = $true
$TextBox1.text ="Please close all running Office applications including Skype for Business!`
When the installer closes running applications, it will not save your work, so do it manually.`
This is an ONLINE installation, about 500MB will be downloaded from internet.`
If you require to install more than one language, please do it one by one.`
Editing and Display language defaults can be set at:`
Start -> Microsoft Office Tools -> Office Language preferences."
$TextBox1.width = 570
$TextBox1.height = 200
$TextBox1.location = New-Object System.Drawing.Point(15,150)
$TextBox1.Font = 'Arial,11'
$textBox1.TextAlign = 'Center'

$Label1 = New-Object system.Windows.Forms.Label
$Label1.text = "Select language pack to Install."
$Label1.AutoSize = $true
$Label1.width = 25
$Label1.height = 10
$Label1.location = New-Object System.Drawing.Point(195,12)
$Label1.Font = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($SelectLanguage,$close,$TextBox1,$Label1))

# This is the same button update text user when selecting a value in combo box. But this one runs when the form loads so that the first entry in the list is resolved.
$Form.Add_Load({
$option = $SelectLanguage.SelectedItem.value
$optionpath = 'O365ProPlusRetail - '+$option
$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
if(Test-Path $(join-path $regpath $optionpath)) {$close.text = 'Remove'} else {$close.text = 'Add'}
})
[void]$form.ShowDialog()