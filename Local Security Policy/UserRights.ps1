using module ".\UserRights.psm1"

$xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        Title="Security Options" Height="600" Width="1200"
        FontSize="18">
    <Grid HorizontalAlignment="Stretch" VerticalAlignment="Stretch">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="4*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="6*"/>
            <ColumnDefinition Width="2*"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="2*"/>
        </Grid.ColumnDefinitions>
        <Grid.Resources>
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

        <ListView Name="MainView" Grid.Row="0" Grid.Column="0" Grid.RowSpan="10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Display Name" Width="Auto" DisplayMemberBinding="{Binding displayname}" />
                    <GridViewColumn Header="Current Value" Width="Auto" DisplayMemberBinding="{Binding currentvalue}" />
                </GridView>
            </ListView.View>
        </ListView>

        <ListView Name="UserView" Grid.Row="0" Grid.Column="1" Grid.RowSpan="2">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Users" Width="Auto" DisplayMemberBinding="{Binding Name}" />
                </GridView>
            </ListView.View>
        </ListView>

        <ListView Name="GroupView" Grid.Row="2" Grid.Column="1" Grid.RowSpan="4">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Groups" Width="Auto" DisplayMemberBinding="{Binding Name}" />
                </GridView>
            </ListView.View>
        </ListView>

        <TextBlock Grid.Row="0" Grid.Column="2" Grid.ColumnSpan="2" Name="PolicyName" TextWrapping="Wrap"></TextBlock>

        <TextBox Name="PolicyInfo" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2"
            TextWrapping="Wrap"
            ScrollViewer.VerticalScrollBarVisibility="Auto">
        </TextBox>

        <Viewbox Grid.Row="2" Grid.Column="2">
            <TextBlock VerticalAlignment="Center"> New Value:</TextBlock>
        </Viewbox>
        <TextBox Name="NewValue" Grid.Row="2" Grid.Column="3"></TextBox>

        <Button Name="Add" Grid.Row="3" Grid.Column="2" Grid.ColumnSpan="2">
            <Viewbox>
                <TextBlock> Add User </TextBlock>
            </Viewbox>
        </Button>

        <Button Name="Remove" Grid.Row="4" Grid.Column="2" Grid.ColumnSpan="2">
            <Viewbox>
                <TextBlock> Remove User </TextBlock>
            </Viewbox>
        </Button>

        <Button Name="Save" Grid.Row="5" Grid.Column="2" Grid.ColumnSpan="2">
            <Viewbox>
                <TextBlock> Save Changes </TextBlock>
            </Viewbox>
        </Button>

    </Grid>
</Window>
"@

[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
$window = [Windows.Markup.XamlReader]::Parse($xaml)

$newvalue = $window.FindName('NewValue')
$policyname = $window.FindName('PolicyName')
$policyinfo = $window.FindName('PolicyInfo')
$mainview = $window.FindName('MainView')
$userview = $window.FindName('UserView')
$groupview = $window.FindName('GroupView')
$addbutton = $window.FindName('Add')
$rmvbutton = $window.FindName('Remove')
$savbutton = $window.FindName('Save')

$userrights = Get-UserRights
$mainview.itemssource = $userrights
[System.Windows.Data.CollectionView] $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView( $mainview.itemssource )
$view.SortDescriptions.Add( [System.ComponentModel.SortDescription]::new( "DisplayName", [System.ComponentModel.ListSortDirection]::Ascending ) )

$userview.itemssource = Get-LocalUser
$groupview.itemssource = Get-LocalGroup

$userview.Add_SelectionChanged({
    $user = $userview.SelectedItems[0]
    $newvalue.text = $user.name
})

$groupview.Add_SelectionChanged({
    $group = $groupview.SelectedItems[0]
    $newvalue.text = $group.name
})


$mainview.Add_SelectionChanged({
    $policy = $mainview.SelectedItems[0]
    $policyname.text = $policy.displayname
    $policyinfo.text = "Recommended values:`n$($policy.recommendedvalue)"
})

$addbutton.Add_Click({
        $policy = $mainview.SelectedItems[0]
        $name = $newvalue.text
        if( $policy -ne $null -and $name -ne "" ){
            $result = Add-NameToUserRights ([ref]$userrights) $policy.constname $name

            $newvalue.text = ""
            $policyinfo.text = ""

            if( $result["status"] -eq $false ){ $policyinfo.text = $result[ "message" ] }
            $mainview.items.refresh()
        }
})

$rmvbutton.Add_Click({
    $policy = $mainview.SelectedItems[0]
    $name = $newvalue.text
    if( $policy -ne $null -and $name -ne "" ){
        $result = Remove-NameFromUserRights ([ref]$userrights) $policy.constname $name
        $mainview.items.refresh()
    }
})

<# Need to implement save button #>

$window.Add_SizeChanged({
    $newvalue.Set_FontSize( $window.actualheight / 15 )
    $policyname.Set_FontSize( $window.actualheight / 35 )
    $policyinfo.Set_FontSize( $window.actualheight / 30 )
})

[void] $window.ShowDialog()
