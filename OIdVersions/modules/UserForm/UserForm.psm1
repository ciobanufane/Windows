using module ".\User.psm1"
function New-ErrorMessageBox{
    param( [String]$msg, [String]$title )
    [System.Windows.Forms.MessageBox]::Show( $msg , $title, "Ok", "Error" )
}
function New-UserListView{
    param( [ref][System.Windows.Forms.ListView]$user_listview )

    $users = (Get-WMIObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | Select-Object name,fullname,disabled,description)

    $user_listview.Value.SuspendLayout()
    $user_listview.Value.Items.Clear()
    # Creating subitems for listview
    $users | ForEach-Object{
        $user = $_
        $user_subitem = New-Object System.Windows.Forms.ListViewItem( $user.Name )
        $user_subitem.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
        [void] $user_subitem.SubItems.AddRange( @($user.fullname, ("{0}" -f -not $user.Disabled), $user.Description) )
        [void] $user_listview.Value.Items.Add( $user_subitem )
    }
    $user_listview.Value.ResumeLayout()
}
function New-UserForm{
    <#
        Load required assemblies
        Alternate version of loading required assemblies
        Add-Type AssemblyName System.Windows.Forms
    #>
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    # <fold Function to reset controls to default
    function Clear-Controls{
        $username.Text = ""
        $fullname.Text = ""
        $description.Text = ""
        $password.Text = ""
        $cpassword.Text = ""
        $disable_checkbox.Checked = $false
    }
    # </fold>
    # <fold Drawing Form
    $user_form = New-Object System.Windows.Forms.Form
    $user_form.Text = "Users"
    $user_form.ClientSize = New-Object System.Drawing.Size( 1500, 420 )
    $user_form.FormBorderStyle = "FixedDialog"
    $user_form.MaximizeBox = $false
    $user_form.MinimizeBox = $true
    $user_form.ControlBox = $true
    $user_form.StartPosition = "CenterScreen"
    $user_form.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    #</fold>
    # <fold ListView to display Users
    $user_listview = New-Object System.Windows.Forms.ListView
    $user_listview.Location = New-Object System.Drawing.Point( 20, 20 )
    $user_listview.Size = New-Object System.Drawing.Size( 1000, 380 )

    $user_listview.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $user_listview.View = "Details"
    $user_listview.FullRowSelect = $true
    $user_listview.Sorting = "Ascending"

    # Defining columns for listview
    [void] $user_listview.Columns.Add("Username", -2 , "Left")
    [void] $user_listview.Columns.Add("Fullname", -2, "Left")
    [void] $user_listview.Columns.Add("Enabled", -2 , "Left")
    [void] $user_listview.Columns.Add("Description", -2 , "Left")

    New-UserListView ([ref]$user_listview)

    # </fold>
    # <fold Controls for user settings
    $username_prompt = New-Object System.Windows.Forms.Label
    $username_prompt.Location = New-Object System.Drawing.Point( 1050, 20 )
    $username_prompt.Size = New-Object System.Drawing.Size( 100, 30 )
    $username_prompt.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $username_prompt.Text = "Username:"

    $username = New-Object System.Windows.Forms.TextBox
    $username.Location = New-Object System.Drawing.Point( 1150, 20 )
    $username.Size = New-Object System.Drawing.Size( 320, 30 )

    $fullname_prompt = New-Object System.Windows.Forms.Label
    $fullname_prompt.Location = New-Object System.Drawing.Point( 1050, 50 )
    $fullname_prompt.Size = New-Object System.Drawing.Size( 100, 30 )
    $fullname_prompt.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $fullname_prompt.Text = "Full name:"

    $fullname = New-Object System.Windows.Forms.TextBox
    $fullname.Location = New-Object System.Drawing.Point( 1150, 50 )
    $fullname.Size = New-Object System.Drawing.Size( 320, 30 )

    $description_prompt = New-Object System.Windows.Forms.Label
    $description_prompt.Location = New-Object System.Drawing.Point( 1050, 80 )
    $description_prompt.Size = New-Object System.Drawing.Size( 100, 30 )
    $description_prompt.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $description_prompt.Text = "Description:"

    $description = New-Object System.Windows.Forms.TextBox
    $description.Location = New-Object System.Drawing.Point( 1150, 80 )
    $description.Size = New-Object System.Drawing.Size( 320, 90 )
    $description.Multiline = $true;
    $description.AcceptsReturn = $true;
    $description.AcceptsTab = $true;
    $description.WordWrap = $true;

    $first_divider = New-Object System.Windows.Forms.Label
    $first_divider.Location = New-Object System.Drawing.Point( 1050, 175 )
    $first_divider.Size = New-Object System.Drawing.Size( 420, 2 )
    $first_divider.BorderStyle = "Fixed3D"
    $first_divider.AutoSize = $false

    $password_prompt = New-Object System.Windows.Forms.Label
    $password_prompt.Location = New-Object System.Drawing.Point( 1050, 180 )
    $password_prompt.Size = New-Object System.Drawing.Size( 150, 30 )
    $password_prompt.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $password_prompt.Text = "Password:"

    $password = New-Object System.Windows.Forms.TextBox
    $password.Location = New-Object System.Drawing.Point( 1200, 180 )
    $password.Size = New-Object System.Drawing.Size( 270, 30 )
    $password.PasswordChar = "*"

    $cpassword_prompt = New-Object System.Windows.Forms.Label
    $cpassword_prompt.Location = New-Object System.Drawing.Point( 1050, 210 )
    $cpassword_prompt.Size = New-Object System.Drawing.Size( 150, 30 )
    $cpassword_prompt.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $cpassword_prompt.Text = "Confirm Password:"

    $cpassword = New-Object System.Windows.Forms.TextBox
    $cpassword.Location = New-Object System.Drawing.Point( 1200, 210 )
    $cpassword.Size = New-Object System.Drawing.Size( 270, 30 )
    $cpassword.PasswordChar = "*"

    $disable_checkbox = New-Object System.Windows.Forms.CheckBox
    $disable_checkbox.Location = New-Object System.Drawing.Point( 1050, 245 )
    $disable_checkbox.AutoSize = $true

    $disable_prompt = New-Object System.Windows.Forms.Label
    $disable_prompt.Location = New-Object System.Drawing.Point( 1070, 240 )
    $disable_prompt.Size = New-Object System.Drawing.Size( 370, 30 )
    $disable_prompt.Font = New-Object System.Drawing.Font( "Segoe UI", 12, [System.Drawing.FontStyle]::Regular )
    $disable_prompt.Text = "Account is disabled"

    # </fold>
    # <fold Creating buttons for Add, Delete and Update
    $add_button = New-Object System.Windows.Forms.Button
    $add_button.Location = New-Object System.Drawing.Point( 1050, 310 )
    $add_button.Size = New-Object System.Drawing.Size( 420, 30 )
    $add_button.Text = "Add"
    $add_button.TextAlign = "MiddleCenter"

    $update_button = New-Object System.Windows.Forms.Button
    $update_button.Location = New-Object System.Drawing.Point( 1050, 340 )
    $update_button.Size = New-Object System.Drawing.Size( 420, 30 )
    $update_button.Text = "Update"
    $update_button.TextAlign = "MiddleCenter"

    $del_button = New-Object System.Windows.Forms.Button
    $del_button.Location = New-Object System.Drawing.Point( 1050, 370 )
    $del_button.Size = New-Object System.Drawing.Size( 420, 30 )
    $del_button.Text = "Delete"
    $del_button.TextAlign = "MiddleCenter"
    # </fold>
    # <fold Functionality for Add button
    $add_button.Add_Click({
        switch( (Search-User $username.Text) ){
            -1 { New-ErrorMessageBox "Need to enter a username" "Add Users" }
            0 {
                if( $password.Text -ne $cpassword.Text ){
                    New-ErrorMessageBox "Confirm password does not match password." "Add Users"
                }
                else{
                    if( $password.Text -eq "" ){
                        New-LocalUser $username.Text -FullName $fullname.Text -Description $description.Text -NoPassword
                    } else {
                        $temp = ConvertTo-SecureString $password.Text -AsPlainText -Force
                        New-LocalUser $username.Text -FullName $fullname.Text -Description $description.Text -Password $temp
                    }
                    switch( $disable_checkbox.Checked ){
                        $true  { Disable-LocalUser $username.Text }
                        $false { Enable-LocalUser $username.Text }
                    }
                    New-UserListView ([ref]$user_listview)
                    Clear-Controls
                }
            }
            1 { New-ErrorMessageBox "User already exists." "Add Users" }
        }
    })
    # </fold>
    # <fold Functionality for Update button
    $update_button.Add_Click({
        switch( (Search-User $username.Text) ){
            -1 { New-ErrorMessageBox "Need to enter a username" "Update Users"}
            0 { New-ErrorMessageBox "User does not exist." "Update Users" }
            1 {
                if( $password.Text -ne $cpassword.Text ){
                    New-ErrorMessageBox "Confirm password does not match password." "Update Users"
                } else {
                    if( $password.Text -eq "" ){
                        Set-LocalUser $username.Text -FullName $fullname.Text -Description $description.Text
                    } else {
                        $temp = ConvertTo-SecureString $password.Text -AsPlainText -Force
                        Set-LocalUser $username.Text -FullName $fullname.Text -Description $description.Text -Password $temp
                    }
                    switch( $disable_checkbox.Checked ){
                        $true  { Disable-LocalUser $username.Text }
                        $false { Enable-LocalUser $username.Text }
                    }
                    New-UserListView ([ref]$user_listview)
                    Clear-Controls
                }
            }
        }
    })
    # </fold>
    # <fold Functionality for Delete button
    $del_button.Add_Click({
        $count = 0;
        $temp = @( $user_listview.SelectedItems )
        if( $temp.Count -eq 0 ){
            New-ErrorMessageBox "Select a user to delete" "Delete Users"
        } else{
            $msg = "Do you want to delete the folowing listed users?`n"
            $user_listview.SelectedItems | ForEach-Object{ $msg += "$($_.Text)`n" }
            $msg_box = [System.Windows.Forms.MessageBox]::Show( $msg, "Delete Users", "YesNo", "Error" )
            if( $msg_box -eq "Yes" ){
                $user_listview.SelectedItems | ForEach-Object{
                    try{
                        Remove-User $_.Text
                    } catch {
                        New-ErrorMessageBox $_.Exception.Message "Delete Users"
                    }
                }
                New-UserListView ([ref]$user_listview)
                Clear-Controls
            }
        }
    })
    # </fold>
    # <fold Updating controls when an item is selected on the ListView
    $user_listview.Add_ItemSelectionChanged({
        if( $_.IsSelected ){
            $item = $user_listview.FindItemWithText( $_.Item.Text )
            $username.Text = $item.SubItems[0].Text
            $fullname.Text = $item.SubItems[1].Text
            $disable_checkbox.Checked = -not [System.Convert]::ToBoolean($item.SubItems[2].Text)
            $description.Text = $item.SubItems[3].Text
        } else {
            Clear-Controls
        }
    })

    # </fold>

    # Adding controls
    $user_form.Controls.AddRange(@($username_prompt,$username,
                                    $fullname_prompt,$fullname,
                                    $description_prompt,$description,
                                    $first_divider,
                                    $password_prompt,$password,
                                    $cpassword_prompt,$cpassword,
                                    $disable_checkbox,$disable_prompt
                                    $add_button,$update_button,$del_button,$user_listview))

    # Show Form
    $user_form.Add_Shown({$user_form.Activate()})
    [void] $user_form.ShowDialog()
}
Export-ModuleMember -Function New-UserForm
