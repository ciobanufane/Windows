$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        Title="Groups" Height="600" Width="1200"
        FontSize="20">

    <Grid Name="GroupGrid" >
        <Grid.RowDefinitions>
            <RowDefinition Height="15*"/>
            <RowDefinition Height="125*"/>
            <RowDefinition Height="30*"/>
            <RowDefinition Height="30*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="200*"/>
            <ColumnDefinition Width="5*"/>
            <ColumnDefinition Width="50*"/>
            <ColumnDefinition Width="70*"/>
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
        </Grid.Resources>

        <ListView Name="GroupView" Grid.Row="0" Grid.Column="0" Grid.RowSpan="20" Height="Auto">
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

        <TextBlock Grid.Column="2" Grid.Row="0" VerticalAlignment="Center"> Group Name: </TextBlock>
        <TextBlock Grid.Column="2" Grid.Row="1" VerticalAlignment="Center"> Group Description: </TextBlock>

        <TextBox Name="GroupName" Grid.Column="3" Grid.Row="0" > </TextBox>
        <TextBox Name="Description" Grid.Column="3" Grid.Row="1" TextWrapping="WrapWithOverflow"> </TextBox>

        <Button Name="AddGroupButton" Grid.Column="3" Grid.Row="2">
            <TextBlock> Add Group </TextBlock>
        </Button>
        <Button Name="DeleteGroupButton" Grid.Column="3" Grid.Row="3">
            <TextBlock> Delete Group </TextBlock>
        </Button>
    </Grid>
</Window>
'@

[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
$window = [Windows.Markup.XamlReader]::Parse($xaml)
$groupview= $window.FindName("GroupView")

$groupname = $window.FindName("GroupName")
$description = $window.FindName("Description")

$addgroupbutton = $window.FindName( "AddGroupButton")
$deletegroupbutton = $window.FindName( "DeleteGroupButton" )
#<fold Function that clears the text of controls
function Clear-Control{
    $groupname.text = ""
    $description.text = ""
}
#</fold>
#<fold Function that resets GroupView
function Reset-Groupview{
    $groupview.Items.Clear()
    Get-WMIObject -Class Win32_group | Select-Object name,description | ForEach-Object{ [void]$groupview.Items.Add( $_ ) }
}
#</fold>
#<fold Update controls when a group is selected
$groupview.Add_SelectionChanged({
    $group = $groupview.SelectedItems[0]
    $groupname.text = $group.name
    $description.text = $group.description
})
#</fold>
#<fold Add Group
$addgroupbutton.Add_Click({
    net group $groupname.text /comment:"$($description.text)" /add > $null
    Reset-GroupView
    Clear-Control
})
#</fold>
#<fold Delete group
$deletegroupbutton.Add_Click({
    $groups = $groupview.SelectedItems

    $message = "Do you want to delete the following groups?`n"
    $groups | ForEach-Object{
        $message += "$($_.name)`n"
    }

    $userinput = [System.Windows.MessageBox]::Show( $message, "Delete Group", "YesNo")
    if( $userinput -eq "Yes" ){
        $groups | ForEach-Object{ net group $_.name /delete > $null }
    }

    Reset-GroupView
    Clear-Control
})
#</fold>
Reset-GroupView
[void] $window.ShowDialog()
