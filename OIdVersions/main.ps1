using module ".\modules\template.psm1"

# <fold Run script as Administrator
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal( $myWindowsID )
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if( -not $myWindowsPrincipal.IsInrole( $adminRole ) ){
    Start-Process "powershell.exe" -ArgumentList $myInvocation.MyCommand.Definition -Verb "runas"
    exit
}

Remove-Variable -Name myWindowsID
Remove-Variable -Name myWindowsPrincipal
Remove-Variable -Name adminRole
# </fold>
# <fold Handle importing modules
$module_path = $PSScriptRoot + "\modules"
if( -not ($env:PSModulePath -match [regex]::escape($module_path)) ){ $env:PSModulePath += ";" + $module_path }
Remove-Variable -Name module_path
Import-Module UserForm
Import-Module UserGroupForm
Import-Module ShareForm
# </fold>
# <fold Function to hide console when script is elevated
function Hide-Console{
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
    $consolePtr = [Console.Window]::GetConsoleWindow();
    [Console.Window]::ShowWindow( $consolePtr, 0 )
}
# </fold>

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )

# <fold Drawing Form
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "Main"
$main_form.ClientSize = New-Object System.Drawing.Size( 1500, 420 )
$main_form.FormBorderStyle = "FixedDialog"
$main_form.MaximizeBox = $false
$main_form.MinimizeBox = $True
$main_form.ControlBox =  $True
$main_form.StartPosition = "CenterScreen"
$main_form.Font = $font

$user_button = New-Object System.Windows.Forms.Button
$user_button.Text = "Users"
$user_button.TextAlign = "MiddleCenter"
$user_button.Location = New-Object System.Drawing.Point( 20,20 )
$user_button.Size = New-Object System.Drawing.Size( 100,100 )
$user_button.Add_Click({ New-UserForm })

$userGroup_button = New-Object System.Windows.Forms.Button
$userGroup_button.Text = "Groups"
$userGroup_button.TextAlign = "MiddleCenter"
$userGroup_button.Location = New-Object System.Drawing.Point( 140,20 )
$userGroup_button.Size = New-Object System.Drawing.Size( 100,100 )
$userGroup_button.Add_Click({ New-UserGroupForm })
# </fold>
# <fold Create Controls
$shareButton = New-Control "Button" 260 20 100 100
$taskButton = New-Control "Button" 380 20 100 100
$accountPolicyButton = New-Control "Button" 500 20 100 100
$auditPolicyButton = New-Control "Button" 620 20 100 100
$userRightsButton = New-Control "Button" 740 20 100 100
$securityOptionsButton = New-Control "Button" 860 20 100 100
$serviceButton = New-Control "Button"
# </fold>
# <fold Defining Controls
$shareButton.Text = "Shares"
$shareButton.TextAlign = "MiddleCenter"
$shareButton.Add_Click({ New-ShareForm })

$taskButton.Text = "Tasks"
$taskButton.TextAlign = "MiddleCenter"
# </fold>

$main_form.Controls.AddRange( @( $user_button, $userGroup_button, $shareButton, $taskButton ) )

$main_form.Add_Shown({
    $main_form.Activate()
    Hide-Console
})
[void] $main_form.ShowDialog()
