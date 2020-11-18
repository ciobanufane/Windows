using module ".\policyhandler.psm1"

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
            <RowDefinition Height="5*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="3*"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
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

        <ListView Name="EventAuditView" Grid.Row="0" Grid.Column="0" Grid.RowSpan="10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Display Name" Width="Auto" DisplayMemberBinding="{Binding DisplayName}" />
                    <GridViewColumn Header="Current Value" Width="Auto" DisplayMemberBinding="{Binding CurrentValue}" />
                </GridView>
            </ListView.View>
        </ListView>

        <TextBlock Grid.Row="0" Grid.Column="1" Grid.ColumnSpan="2" Name="PolicyName" TextWrapping="Wrap"></TextBlock>

        <TextBox Name="PolicyInfo" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="2"
            TextWrapping="Wrap"
            ScrollViewer.VerticalScrollBarVisibility="Auto">
        </TextBox>

        <Viewbox Grid.Row="2" Grid.Column="1">
            <TextBlock VerticalAlignment="Center"> Current Value: </TextBlock>
        </Viewbox>
        <TextBox Name="CurrentValue" Grid.Row="2" Grid.Column="2" IsReadOnly="True"></TextBox>

        <Viewbox Grid.Row="3" Grid.Column="1">
            <TextBlock VerticalAlignment="Center"> New Value:</TextBlock>
        </Viewbox>
        <TextBox Name="NewValue" Grid.Row="3" Grid.Column="2"></TextBox>

        <Button Name="UpdatePolicy" Grid.Row="4" Grid.Column="1" Grid.ColumnSpan="2">
            <Viewbox>
                <TextBlock> Update Policy </TextBlock>
            </Viewbox>
        </Button>
    </Grid>
</Window>
"@

[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
$window = [Windows.Markup.XamlReader]::Parse($xaml)

$currentvalue = $window.FindName("CurrentValue")
$newvalue = $window.FindName("NewValue")
$policyname = $window.FindName("PolicyName")
$policyinfo = $window.FindName("PolicyInfo")
$eventauditview = $window.FindName("EventAuditView")
$updatepolicybutton = $window.FindName("UpdatePolicy")

$uri = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTVkcq6ZsJrsaUAtkzxGKdfXeRepQFW9uWRcrOUlePA8SrhtlzYvS8IiTzRQlrPxhp6lz9YMiAy4QUN/pub?gid=1307811099&single=true&output=csv"
$filename = "ea"
$area = "Event Audit"

$handler = [PolicyHandler]::new( $uri, $filename, $area )
$handler.getInfoPolicies()

function Clear-Controls{
    $currentvalue.text = ""
    $newvalue.text     = ""
}

function Reset-EventAuditView{
    $eventauditview.Items.Clear()
    $handler.getCurrentPolicies()

    $handler.info.GetEnumerator() | Sort-Object { $_.Value.DisplayName } | ForEach-Object{
        $constname = $_.name
        $policy = $handler.getInfoPolicy( $constname )
        $cvalue = $handler.getCurrentPolicy( $constname )

        $item = New-Object System.Windows.Controls.ListViewItem
        $item.tag = $constname
        $item.AddChild( [PSCustomObject]@{ "displayname" = $policy.displayname; "currentvalue" = $cvalue } )
        [void] $eventauditview.Items.Add( $item )
    }
}

$eventauditview.Add_SelectionChanged({
    $policy = $eventauditview.SelectedItems[0]
    if( $policy -ne $null ){
        $constname = $policy.tag
        $displayname = $policy.content.displayname
        $cvalue = $policy.content.currentvalue

        $info = "Possible values:`n"
        $handler.getInfoPolicy( $constname ).possiblevalues.GetEnumerator() | Sort-Object | ForEach-Object{
            $key = $_.Name
            $value = $_.Value

            if( $value -eq "" ){
                $info += "$key`n"
            } else{
                $info += "$key = $value`n"
            }
        }
        $info += "`nRecommended values:`n"
        $info += "$($handler.getInfoPolicy( $constname ).recommendedvalue)`n"

        $policyname.text = $displayname
        $policyinfo.text = $info
        $currentvalue.text = $cvalue
    }
})

$updatepolicybutton.Add_Click({
    $policy = $eventauditview.SelectedItems[0]
    $value = $newvalue.text
    if( $policy -ne $null -or $value -eq "" ){
        $constname = $policy.tag
        $result = $handler.updatePolicy( $constname, $value )
        if( $result -eq $false ){
            [System.Windows.MessageBox]::Show( "Failed to update policy with the new value`nPolicy = $($policy.content.displayname)`nValue = $value" )
        }
        Reset-EventAuditView
        Clear-Controls
    }
})

$window.Add_SizeChanged({
    $currentvalue.Set_FontSize( $window.actualheight / 15 )
    $newvalue.Set_FontSize( $window.actualheight / 15 )
    $policyname.Set_FontSize( $window.actualheight / 35 )
    $policyinfo.Set_FontSize( $window.actualheight / 30 )
})

Reset-EventAuditView
[void] $window.ShowDialog()
