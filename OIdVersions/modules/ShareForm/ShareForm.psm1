using module "..\template.psm1"
using module ".\Share.psm1"

function New-ShareListView{
    param( [ref][System.Windows.Forms.ListView] $shareListView )

    $shares = Get-SMBShare
    $shareListView.Value.SuspendLayout()
    $shareListView.Value.Items.Clear()

    $shares | ForEach-Object{
        $share = $_
        $shareSubItem = New-Object System.Windows.Forms.ListViewItem( $share.Name )
        $shareSubItem.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
        $shareSubItem.SubItems.Add( $share.Path )
        $shareSubItem.SubItems.Add( $share.Description )
        $shareListView.Value.Items.Add( $shareSubItem )
    }
    $shareListView.Value.ResumeLayout()
}

function New-ShareForm{

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    # <fold Creating form
    $shareForm = New-Object System.Windows.Forms.Form
    $shareForm.Text = "Shares"
    $shareForm.ClientSize = New-Object System.Drawing.Size( 1120, 420 )
    $shareForm.FormBorderStyle = "FixedDialog"
    $shareForm.MaximizeBox = $false
    $shareForm.MinimizeBox = $true
    $shareForm.ControlBox = $true
    $shareForm.StartPosition = "CenterScreen"
    $shareForm.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    # </fold>
    # <fold Initializing Controls
    $shareListView = New-Control "ListView" 20 20 600 380
    $shareNameLabel = New-Control "Label" 640 20 110 30 "Share Name:"
    $shareNamePrompt = New-Control "TextBox" 750 20 350 30
    $sharePathLabel = New-Control "Label" 640 60 110 30 "Path Name:"
    $sharePathPrompt = New-Control "TextBox" 750 60 350 30
    $sharePathButton = New-Control "Button" 750 100 80 30 "Browse"
    $sharePath = New-Object System.Windows.Forms.FolderBrowserDialog
    $shareDescLabel = New-Control "Label" 640 140 110 30 "Description:"
    $shareDescPrompt = New-Control "TextBox" 750 140 350 150
    $shareAddButton = New-Control "Button" 750 310 350 30 "Add"
    $shareUpdateButton = New-Control "Button" 750 340 350 30 "Update"
    $shareDelButton = New-Control "Button" 750 370 350 30 "Delete"
    # </fold>
    # <fold Defining Controls
    $shareListView.View = "Details"
    $shareListView.Sorting = "Ascending"
    $shareListView.FullRowSelect = $true
    $shareListView.MultiSelect = $false
    $shareListView.HideSelection = $false
    [void] $shareListView.Columns.Add( "Share Name", -2, "Left" )
    [void] $shareListView.Columns.Add( "Path Name", -1, "Left" )
    [void] $shareListView.Columns.Add( "Description", -2, "Left" )
    New-ShareListView ([ref]$shareListView)
    $shareListView.Add_ItemSelectionChanged({
            if( $_.IsSelected){
                $share = $shareListView.FindItemWithText( $_.Item.Text )
                $shareNamePrompt.Text = $share.SubItems[0].Text
                $sharePathPrompt.Text = $share.SubItems[1].Text
                $shareDescPrompt.Text = $share.SubItems[2].Text
            }
    })

    $sharePathButton.TextAlign = "MiddleCenter"
    $sharePathButton.Add_Click({
        $result = $sharePath.ShowDialog()
        if( $result -eq "OK" ){ $sharePathPrompt.Text = $sharePath.SelectedPath }
    })

    $shareDescPrompt.MultiLine = $true
    $shareDescPrompt.AcceptsReturn = $true
    $shareDescPrompt.AcceptsTab = $true
    $shareDescPrompt.WordWrap = $true

    $shareAddButton.TextAlign = "MiddleCenter"
    $shareAddButton.Add_Click({
        try{
            New-Share -Name $shareNamePrompt.Text -Path $sharePathPrompt.Text -Description $shareDescPrompt.Text
            Clear-Controls @( [ref]$shareNamePrompt, [ref]$sharePathPrompt, [ref]$shareDescPrompt )
            New-ShareListView ([ref]$shareListView)
        } catch {
            New-ErrorMessageBox $_.Exception.Message "Add Share"
        }
    })
    $shareUpdateButton.TextAlign = "MiddleCenter"
    $shareUpdateButton.Add_Click({
        try{
            Set-Share -Name $shareNamePrompt.Text -Description $shareDescPrompt.Text
            Clear-Controls @( [ref]$shareNamePrompt, [ref]$sharePathPrompt, [ref]$shareDescPrompt )
            New-ShareListView ([ref]$shareListView)
        } catch {
            New-ErrorMessageBox $_.Exception.Message "Update Share"
        }
    })
    $shareDelButton.TextAlign = "MiddleCenter"
    $shareDelButton.Add_Click({
        try{
            Remove-Share -Name $shareNamePrompt.Text
            Clear-Controls @( [ref]$shareNamePrompt, [ref]$sharePathPrompt, [ref]$shareDescPrompt )
            New-ShareListView ([ref]$shareListView)
        } catch {
            New-ErrorMessageBox $_.Exception.Message "Delete Share"
        }
    })
    # </fold>

    $shareForm.Controls.AddRange( @($shareListView, $shareNameLabel, $shareNamePrompt,
                                    $sharePathLabel, $sharePathPrompt, $sharePathButton
                                    $shareDescLabel, $shareDescPrompt
                                    $shareAddButton, $shareUpdateButton, $shareDelButton))
    $shareForm.Add_Shown({ $shareForm.Activate() })
    [void] $shareForm.ShowDialog()
}

Export-ModuleMember -Function New-ShareForm
