$xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        Title="Users" Height="600" Width="1200"
        FontSize="20">
    <Grid Name="TestGrid" >
        <Grid.RowDefinitions>
            <RowDefinition Height="5*"/>
            <RowDefinition Height="5*"/>
            <RowDefinition Height="20*"/>
            <RowDefinition Height="5*"/>
            <RowDefinition Height="5*"/>
            <RowDefinition Height="5*"/>
            <RowDefinition Height="12*"/>
            <RowDefinition Height="12*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="130*"/>
            <ColumnDefinition Width="3*"/>
            <ColumnDefinition Width="30*"/>
            <ColumnDefinition Width="40*"/>
        </Grid.ColumnDefinitions>
        <Grid.Resources>
            <Style TargetType="{x:Type StackPanel}">
                <Setter Property="Margin" Value="5" />
            </Style>
            <Style TargetType="{x:Type TextBox}">
                <Setter Property="Margin" Value="5" />
            </Style>
            <Style TargetType="{x:Type ListView}">
                <Setter Property="Margin" Value="5" />
            </Style>
            <Style TargetType="{x:Type TextBlock}">
                <Setter Property="Margin" Value="5" />
            </Style>
            <Style TargetType="{x:Type Button}">
                <Setter Property="Margin" Value="5" />
            </Style>
            <Style TargetType="{x:Type CheckBox}">
                <Setter Property="Margin" Value="5" />
            </Style>
        </Grid.Resources>

        <ListView Name="UserView" Grid.Row="0" Grid.Column="0" Grid.RowSpan="10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Name" Width="Auto" DisplayMemberBinding="{Binding Name}" />
                    <GridViewColumn Header="Fullname" Width="Auto" DisplayMemberBinding="{Binding Fullname}" />
                    <GridViewColumn Header="Disabled" Width="Auto" DisplayMemberBinding="{Binding Disabled}" />
                    <GridViewColumn Header="Description" Width="Auto" DisplayMemberBinding="{Binding Description}" />
                </GridView>
            </ListView.View>
        </ListView>

        <StackPanel Grid.Column="1" Grid.Row="0" Grid.RowSpan="10" Height="Auto" Orientation="Horizontal">
            <Separator Style="{StaticResource {x:Static ToolBar.SeparatorStyleKey}}" />
        </StackPanel>

        <TextBlock Grid.Column="2" Grid.Row="0" VerticalAlignment="Center"> Username: </TextBlock>
        <TextBlock Grid.Column="2" Grid.Row="1" VerticalAlignment="Center"> Fullname: </TextBlock>
        <TextBlock Grid.Column="2" Grid.Row="2" VerticalAlignment="Center"> Description: </TextBlock>
        <TextBlock Grid.Column="2" Grid.Row="3" VerticalAlignment="Center"> Password: </TextBlock>
        <TextBlock Grid.Column="2" Grid.Row="4" VerticalAlignment="Center"> Confirm Password: </TextBlock>
        <TextBlock Grid.Column="2" Grid.Row="5" VerticalAlignment="Center"> Disabled: </TextBlock>

        <TextBox Name="UserName" Grid.Column="3" Grid.Row="0"/>
        <TextBox Name="FullName" Grid.Column="3" Grid.Row="1"/>
        <TextBox Name="Description" Grid.Column="3" Grid.Row="2" TextWrapping="WrapWithOverflow"/>
        <TextBox Name="Password" Grid.Column="3" Grid.Row="3" />
        <TextBox Name="CPassword" Grid.Column="3" Grid.Row="4"/>
        <CheckBox Name="Disabled" Grid.Column="3" Grid.Row="5" VerticalContentAlignment="Center" />

        <Button Name="AddUserButton" Grid.Column="3" Grid.Row="6">
            <TextBlock> Add User</TextBlock>
        </Button>
        <Button Name="DeleteUserButton" Grid.Column="3" Grid.Row="7">
            <TextBlock> Delete User</TextBlock>
        </Button>
    </Grid>
</Window>
"@

[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
$window = [Windows.Markup.XamlReader]::Parse($xaml)

$userview = $window.FindName( "UserView" )

$adduserbutton = $window.FindName( "AddUserButton" )
$deleteuserbutton = $window.FindName( "DeleteUserButton" )

$username = $window.FindName( "UserName" )
$fullname = $window.FindName( "FullName" )
$description = $window.FindName( "Description" )
$password = $window.FindName( "Password" )
$cpassword = $window.FindName( "CPassword" )
$disabled = $window.FindName( "Disabled" )

#<fold Function that clears the text of controls
function Clear-Control{
    $username.text    = ""
    $fullname.text    = ""
    $description.text = ""
    $password.text    = ""
    $cpassword.text   = ""
    $disabled.IsChecked = $false
}
#</fold>
#<fold Function that resets UserView
function Reset-UserView{
    $userview.Items.Clear()
    $users = Get-WMIObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | Select-Object name,fullname,disabled,description
    $users | ForEach-Object{ [void] $userview.Items.Add( $_ ) }
}
#</fold>
#<fold Update controls when a user is selected
$userview.Add_SelectionChanged({
    $user = $userview.SelectedItems[0]
    $username.text = $user.name
    $fullname.text = $user.fullname
    $description.text = $user.description
    if( $user.disabled -eq 'true' ){
        $disabled.IsChecked = $true
    } else {
        $disabled.IsChecked = $false
    }
})
#</fold>
#<fold Add user
$adduserbutton.Add_Click({
    if( $disabled.IsChecked -eq $true ){
        net user $username.text $password.text /fullname:"$($fullname.text)" /comment:"$($description.text)" /active:no /add > $null
    } else {
        net user $username.text $password.text /fullname:"$($fullname.text)" /comment:"$($description.text)" /add > $null
    }
    Reset-UserView
    Clear-Control
})
#</fold>
#<fold Delete user
$deleteuserbutton.Add_Click({
    $users = $userview.SelectedItems

    $message = "Do you want to delete the following users?`n"
    $users | ForEach-Object{
        $message += "$($_.name)`n"
    }

    $userinput = [System.Windows.MessageBox]::Show( $message, "Delete User", "YesNo"  )
    if( $userinput -eq 'Yes' ){
        $users | ForEach-Object{ net user $_.name /delete > $null }
    }

    Reset-UserView
    Clear-Control
})
#</fold>

Reset-UserView
[void] $window.ShowDialog()
