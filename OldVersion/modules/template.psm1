
<#
    Passing objects by reference to functions
        In order to modify the object, you have to acesss the Value property of the object
            The Value property contains the object data
#>
function New-ErrorMessageBox{
    param( [String]$msg, [String]$title )
    [System.Windows.Forms.MessageBox]::Show( $msg , $title, "Ok", "Error" )
}

function Clear-Controls{
    param( [System.Collections.ArrayList]$controlArray )
    $controlArray | ForEach-Object{ $_.Value.Text = "" }
}

function New-Control{
    param( [String] $control, [int] $x, [int] $y, [int] $width, [int] $height, [String] $text = "" )

    $assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    if( ($assembly.GetTypes() | Where-Object{ $_.name -like $control }) -eq $null ){
        return $null
    }
    $c = New-Object System.Windows.Forms.$control
    $c.location = New-Object System.Drawing.Point( $x, $y )
    $c.Size = New-Object System.Drawing.Size( $width, $height )
    $c.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $c.Text = $text
    return $c
}
