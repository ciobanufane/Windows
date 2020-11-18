using module "..\template.psm1"
using module ".\Group.psm1"
using module ".\UserGroup.psm1"

function New-GroupListView{
    param( [ref][System.Windows.Forms.ListView]$group_listview )

    $groups = (Get-LocalGroup)

    $group_listview.Value.SuspendLayout()
    $group_listview.Value.Items.Clear()

    $groups | ForEach-Object{
        $group = $_
        $group_subitem = New-Object System.Windows.Forms.ListViewItem( $group.Name )
        $group_subitem.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
        $group_subitem.SubItems.Add( $group.Description )
        [void] $group_listview.Value.Items.Add( $group_subitem )
    }
    $group_listview.Value.ResumeLayout()
}
function New-GroupMemberListView{
    param( [String]$groupName, [ref][System.Windows.Forms.ListView]$groupMember_listview, [ref][System.Windows.Forms.ListView]$notGroupMember_listview )

    $users = Get-WMIObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | Select-Object name

    $groupMember_listview.Value.SuspendLayout()
    $groupMember_listview.Value.Items.Clear()
    $notGroupMember_listview.Value.SuspendLayout()
    $notGroupMember_listview.Value.Items.Clear()

    $users | ForEach-Object{
        $user = $_
        $user_subitem = New-Object System.Windows.Forms.ListViewItem( $user.Name )
        $user_subitem.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
        if(( Get-LocalGroupMember "$($groupName)" $user.Name -ErrorAction SilentlyContinue ) -ne $null ){
            [void] $groupMember_listview.Value.Items.Add( $user_subitem )
        } else {
            [void] $notGroupMember_listview.Value.Items.Add( $user_subitem )
        }
    }
    $groupMember_listview.Value.ResumeLayout()
    $notGroupMember_listview.Value.ResumeLayout()
}
function New-UserGroupForm{

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    # <fold Form for UserGroup
    $userGroup_form = New-Object System.Windows.Forms.Form
    $userGroup_form.Text = "Group Member"
    $userGroup_form.ClientSize = New-Object System.Drawing.Size( 1500, 420 )
    $userGroup_form.FormBorderStyle = "FixedDialog"
    $userGroup_form.MaximizeBox = $false
    $userGroup_form.MinimizeBox = $true
    $userGroup_form.ControlBox = $true
    $userGroup_form.StartPosition = "CenterScreen"
    $userGroup_form.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    # </fold>
    # <fold Control for Group ListView
    $group_listview = New-Object System.Windows.Forms.ListView
    $group_listview.Location = New-Object System.Drawing.Point( 20, 20 )
    $group_listview.Size = New-Object System.Drawing.Size( 540, 380 )

    $group_listview.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $group_listview.View = "Details"
    $group_listview.FullRowSelect = $true
    $group_listview.Sorting = "Ascending"
    $group_listview.MultiSelect = $false
    $group_listview.HideSelection = $false

    # Defining columns for listview
    [void] $group_listview.Columns.Add("Group Name", -2 , "Left" )
    [void] $group_listview.Columns.Add("Group Description", -2, "Left" )
    New-GroupListView ( [ref]$group_listview )
    # </fold>
    # <fold Controls for Displaying and Modifying Group Information
    $first_divider = New-Object System.Windows.Forms.Label
    $first_divider.Location = New-Object System.Drawing.Point( 570, 20 )
    $first_divider.Size = New-Object System.Drawing.Size( 2, 380 )
    $first_divider.BorderStyle = "Fixed3D"
    $first_divider.AutoSize = $false

    $groupName_label = New-Object System.Windows.Forms.Label
    $groupName_label.Location = New-Object System.Drawing.Point( 580, 20 )
    $groupName_label.Size = New-Object System.Drawing.Size( 110, 30 )
    $groupName_label.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $groupName_label.Text = "Group Name:"

    $groupName_prompt = New-Object System.Windows.Forms.TextBox
    $groupName_prompt.Location = New-Object System.Drawing.Point( 690, 20 )
    $groupName_prompt.Size = New-Object System.Drawing.Size( 230, 60 )

    $groupDescription_label = New-Object System.Windows.Forms.Label
    $groupDescription_label.Location = New-Object System.Drawing.Point( 580, 60 )
    $groupDescription_label.Size = New-Object System.Drawing.Size( 110, 30 )
    $groupDescription_label.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $groupDescription_label.Text = "Description:"

    $groupDescription_prompt = New-Object System.Windows.Forms.TextBox
    $groupDescription_prompt.Location = New-Object System.Drawing.Point( 690, 60 )
    $groupDescription_prompt.Size = New-Object System.Drawing.Size( 230, 280 )
    $groupDescription_prompt.Multiline = $true;
    $groupDescription_prompt.AcceptsReturn = $true;
    $groupDescription_prompt.AcceptsTab = $true;
    $groupDescription_prompt.WordWrap = $true;

    $groupAdd_button = New-Object System.Windows.Forms.Button
    $groupAdd_button.Location = New-Object System.Drawing.Point( 580, 350 )
    $groupAdd_button.Size = New-Object System.Drawing.Size( 340, 20 )
    $groupAdd_button.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $groupAdd_button.Text = "Add"
    $groupAdd_button.TextAlign = "MiddleCenter"

    $groupDelete_button = New-Object System.Windows.Forms.Button
    $groupDelete_button.Location = New-Object System.Drawing.Point( 580, 380 )
    $groupDelete_button.Size = New-Object System.Drawing.Size( 340, 20 )
    $groupDelete_button.Font = $groupDescription_label.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $groupDelete_button.Text = "Delete"
    $groupDelete_button.TextAlign = "MiddleCenter"

    $second_divider = New-Object System.Windows.Forms.Label
    $second_divider.Location = New-Object System.Drawing.Point( 935, 20 )
    $second_divider.Size = New-Object System.Drawing.Size( 2, 380 )
    $second_divider.BorderStyle = "Fixed3D"
    $second_divider.AutoSize = $false
    # </fold>
    # <fold Control for NotGroupMember ListView
    $notGroupMember_listview = New-Object System.Windows.Forms.ListView
    $notGroupMember_listview.Location = New-Object System.Drawing.Point( 950, 20 )
    $notGroupMember_listview.Size = New-Object System.Drawing.Size( 200, 380 )

    $notGroupMember_listview.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $notGroupMember_listview.View = "Details"
    $notGroupMember_listview.FullRowSelect = $true
    $notGroupMember_listview.Sorting = "Ascending"
    $notGroupMember_listview.HideSelection = $false;

    # Defining columns for listview
    [void] $notGroupMember_listview.Columns.Add("User Not In Group", -2 , "Left" )
    # </fold>
    # <fold Controls for Add and Delete GroupMember
    $addMemberButton = New-Object System.Windows.Forms.Button
    $addMemberButton.Location = New-Object System.Drawing.Point( 1170, 240 )
    $addMemberButton.Size = New-Object System.Drawing.Size( 90, 20 )
    $addMemberButton.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $addMemberbutton.TextAlign = "MiddleCenter"
    $addMemberButton.Text = "Add"

    $delMemberButton = New-Object System.Windows.Forms.Button
    $delMemberButton.Location = New-Object System.Drawing.Point( 1170, 270 )
    $delMemberButton.Size = New-Object System.Drawing.Size( 90, 20 )
    $delMemberButton.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $delMemberbutton.TextAlign = "MiddleCenter"
    $delMemberButton.Text = "Delete"
    # </fold>
    # <fold Control for GroupMember ListView
    $groupMember_listview = New-Object System.Windows.Forms.ListView
    $groupMember_listview.Location = New-Object System.Drawing.Point( 1280, 20 )
    $groupMember_listview.Size = New-Object System.Drawing.Size( 200, 380 )

    $groupMember_listview.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $groupMember_listview.View = "Details"
    $groupMember_listview.Sorting = "Ascending"
    $groupMember_listview.HideSelection = $false;
    $groupMember_listview.FullRowSelect = $true;

    # Defining columns for listview
    [void] $groupMember_listview.Columns.Add("User In Group", -2 , "Left" )
    # </fold>
    # <fold Updating controls when an item is selected on Group ListView
    $group_listview.Add_ItemSelectionChanged({
        if( $_.isSelected ){
            $item = $group_listview.FindItemWithText( $_.Item.Text )
            $groupName_prompt.Text = $item.SubItems[0].Text
            $groupDescription_prompt.Text = $item.SubItems[1].Text
            New-GroupMemberListView $item.SubItems[0].Text ([ref]$groupMember_listview) ([ref]$notGroupMember_listview)
        }
    })
    # </fold>
    # <fold Functionality for Add Group button
    $groupAdd_button.Add_Click({
        switch((Search-Group $groupName_prompt.Text)){
            -1{ New-ErrorMessageBox "Need to enter a group name" "Add Group" }
            0{
                New-Group $groupName_prompt.Text $groupDescription_prompt.Text
                $groupName_prompt.Text = ""
                $groupDescription_prompt.Text = ""
                New-GroupListView ( [ref]$group_listview )
            }
            1{ New-ErrorMessageBox "Group already exists" "Add Group" }
        }
    })
    # </fold>
    # <fold Functionality for Delete Group button
    $groupDelete_button.Add_Click({
        switch((Search-Group $groupName_prompt.Text)){
            -1{ New-ErrorMessageBox "Need to enter a group name" "Delete Group" }
            0{ New-ErrorMessageBox "Group does not exist" "Delete Group" }
            1{
                Remove-Group $groupName_prompt.Text
                $groupName_prompt.Text = ""
                $groupDescription_prompt.Text = ""
                New-GroupListView ( [ref]$group_listview )
            }
        }
    })
    # </fold>
    # <fold Functionality for AddMember button
    $addMemberButton.Add_Click({
        $selected_group = $group_listview.SelectedItems.SubItems[0].Text
        if((Get-LocalGroup $selected_group -ErrorAction SilentlyContinue) -ne $null ){
            $notGroupMember_listview.SelectedItems | ForEach-Object{
                $user = $_.Text.trim()
                try{
                    Add-LocalGroupMemberE $selected_group $user
                } catch {
                    New-ErrorMessageBox $_ "Add Group Member"
                }
            }
            New-GroupMemberListView $selected_group ([ref]$groupMember_listview) ([ref]$notGroupMember_listview)
        } else {
            New-ErrorMessageBox "Select a group first" "Add Group Member"
        }
    })
    # </fold>
    # <fold Functionality for DelMember buttons
    $delMemberButton.Add_Click({
        $selected_group = $group_listview.SelectedItems.SubItems[0].Text
        if((Get-LocalGroup $selected_group -ErrorAction SilentlyContinue) -ne $null ){
            $groupMember_listview.SelectedItems | ForEach-Object{
                $user = $_.Text
                try{
                    Remove-LocalGroupMemberE $selected_group $user
                } catch {
                    New-ErrorMessageBox $_ "Delete Group Member"
                }
            }
            New-GroupMemberListView $selected_group ([ref]$groupMember_listview) ([ref]$notGroupMember_listview)
        } else {
            New-ErrorMessageBox "Select a group first" "Delete Group Member"
        }
    })
    # </fold>

    $userGroup_form.Controls.AddRange( @( $group_listview, $notGroupMember_listview, $groupMember_listview,
                                            $addMemberButton, $delMemberButton
                                            $groupName_label, $groupName_prompt,
                                            $groupDescription_label, $groupDescription_prompt,
                                            $groupAdd_button, $groupDelete_button,
                                            $first_divider, $second_divider ) )
    $userGroup_form.Add_Shown({$userGroup_form.Activate()})
    [void] $userGroup_form.ShowDialog()
}
Export-ModuleMember -Function New-UserGroupForm
