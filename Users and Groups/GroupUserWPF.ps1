$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d"
    Title="Group Users" Height="600" Width="1200"
    FontSize="16">

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="100*"/>
            <RowDefinition Height="10*"/>
            <RowDefinition Height="10*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="250*"/>
            <ColumnDefinition Width="5*"/>
            <ColumnDefinition Width="75*"/>
            <ColumnDefinition Width="60*"/>
            <ColumnDefinition Width="75*"/>
        </Grid.ColumnDefinitions>
        <Grid.Resources>
            <Style TargetType="{x:Type StackPanel}">
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
        </Grid.Resources>

        <ListView Name="GroupView"
            Grid.Row="0"
            Grid.Column="0"
            Grid.RowSpan="10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="Auto" DisplayMemberBinding="{Binding Name}">
                        <GridViewColumnHeader HorizontalContentAlignment="Left"> Group Name </GridViewColumnHeader>
                    </GridViewColumn>
                    <GridViewColumn Width="Auto" DisplayMemberBinding="{Binding Description}">
                        <GridViewColumnHeader HorizontalContentAlignment="Left"> Group Description </GridViewColumnHeader>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>

        <StackPanel Grid.Column="1" Grid.Row="0" Grid.RowSpan="10" Height="Auto" Orientation="Horizontal">
            <Separator Style="{StaticResource {x:Static ToolBar.SeparatorStyleKey}}" />
        </StackPanel>

        <ListView Name="NotGroupUserView"
            Grid.Row="0"
            Grid.Column="2"
            Grid.RowSpan="10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="Auto" DisplayMemberBinding="{Binding Name}">
                        <GridViewColumnHeader HorizontalContentAlignment="Left"> User not in group </GridViewColumnHeader>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>

        <Button Name="AddUser" Grid.Column="3" Grid.Row="1">
            <TextBlock> Add User </TextBlock>
        </Button>
        <Button Name="RemoveUser" Grid.Column="3" Grid.Row="2">
            <TextBlock> Remove User </TextBlock>
        </Button>

        <ListView Name="GroupUserView"
            Grid.Row="0"
            Grid.Column="4"
            Grid.RowSpan="10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="Auto" DisplayMemberBinding="{Binding Name}">
                        <GridViewColumnHeader HorizontalContentAlignment="Left"> User in group </GridViewColumnHeader>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>
    </Grid>
</Window>
'@

[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
$window = [Windows.Markup.XamlReader]::Parse($xaml)

#<fold Finding Controls
$groupview = $window.FindName("GroupView")
$groupuserview = $window.FindName("GroupUserView")
$notgroupuserview = $window.FindName("NotGroupUserView")
$addUser = $window.FindName("AddUser")
$removeUser = $window.FindName("RemoveUser")
#</fold>
#<fold Populate GroupView
Get-WMIObject -Class Win32_group | Select-Object name,description | ForEach-Object{ [void] $groupview.Items.Add( $_ ) }
#</fold>
#<fold Function that resets UserViews
function Reset-Userview{
    <# Gathering data #>
    $group = $groupview.SelectedItems[0]
    $groupObject = Get-WMIObject -Class Win32_Group -Filter "Name='$($group.Name)'"
    $groupUsers = Get-WMIObject -Class Win32_GroupUser | Where-Object{ $_.GroupComponent -match "$($group.Name)" } | ForEach-Object{ [wmi]$_.PartComponent } | Select-Object name
    $allUsers = Get-WMIObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | Select-Object name

    <# NotGroupUserView #>
    $notgroupuserview.Items.Clear()
    $allUsers | ForEach-Object{ if( $_.name -notin $groupUsers.name ){ [void] $notgroupuserview.Items.Add( $_ ) } }
    <# Readjust column width to match any new data #>
    $notgroupuserview.View.Columns | ForEach-Object{
        if( [Double]::IsNaN( $_.Width ) ){
            $_.Width = $_.ActualWidth
        }
        $_.Width = [Double]::NaN
    }

    <# GroupUserView #>
    $groupuserview.Items.Clear()
    $groupUsers | ForEach-Object{ [void] $groupuserview.Items.Add( $_ ) }
    <# Readjust column width to match any new data #>
    $groupuserview.View.Columns | ForEach-Object{
        if( [Double]::IsNaN( $_.Width ) ){
            $_.Width = $_.ActualWidth
        }
        $_.Width = [Double]::NaN
    }
}
#</fold>
#<fold Reset UserViews when an item is selected on GroupView
$groupview.Add_SelectionChanged({
    Reset-Userview
})
# </fold>
#<fold Add user to a group
$addUser.Add_Click({
    $group = $groupview.SelectedItems[0]
    $selectedUsers = $notgroupuserview.SelectedItems
    $selectedUsers | ForEach-Object{
        net localgroup $group.Name $_.Name /add
    }
    Reset-Userview
})
#</fold>
#<fold Remove user from a group
$removeUser.Add_Click({
    $group = $groupview.SelectedItems[0]
    $selectedUsers = $groupuserview.SelectedItems
    $selectedUsers | ForEach-Object{
        net localgroup $group.Name $_.Name /delete
    }
    Reset-Userview
})
#</fold>

[void] $window.ShowDialog()
