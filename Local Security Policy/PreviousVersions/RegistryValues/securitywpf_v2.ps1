using module ".\securityoptions_v2.psm1"

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

        <ListView Name="SecurityOptionsView" Grid.Row="0" Grid.Column="0" Grid.RowSpan="10">
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

function Show-SecurityOptions{
    [void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
    $window = [Windows.Markup.XamlReader]::Parse($xaml)

    $currentvalue = $window.FindName("CurrentValue")
    $newvalue = $window.FindName("NewValue")
    $policyname = $window.FindName("PolicyName")
    $policyinfo = $window.FindName("PolicyInfo")
    $securityoptionsview = $window.FindName("SecurityOptionsView")
    $updatepolicybutton = $window.FindName("UpdatePolicy")

    $handler = [SecurityOptionsHandler]::new()
    $handler.requestInfoSecurityOptions()
    $handler.getInfoSecurityOptions()
    $handler.getCurrentSecurityOptions()

    function Clear-Controls{
        $currentvalue.text = ""
        $newvalue.text     = ""
    }

    function Reset-SecurityOptionsView{
        $securityoptionsview.Items.Clear()
        $handler.getCurrentSecurityOptions()

        $handler.infoSO.GetEnumerator() | Sort-Object{ $_.Value.DisplayName } | ForEach-Object{
            $registrypath = $_.Name
            $policy = $handler.getInfoPolicy( $registrypath )
            $cvalue = $handler.getCurrentPolicy( $registrypath )

            $item = New-Object System.Windows.Controls.ListViewItem
            $item.tag = $registrypath
            $item.AddChild( [PSCustomObject]@{ "displayname" = $policy.displayname; "currentvalue" = $cvalue} )
            [void] $securityoptionsview.Items.Add( $item )
        }
    }

    $securityoptionsview.Add_SelectionChanged({
        $policy = $securityoptionsview.SelectedItems[0]
        if( $policy -ne $null ){
            $registrypath = $policy.tag
            $displayname = $policy.content.displayname
            $cvalue = $policy.content.currentvalue

            $info = "Possible values:`n"
            $handler.getInfoPolicy( $registrypath ).possiblevalues.GetEnumerator() | Sort-Object | ForEach-Object{
                $key = $_.Name
                $value = $_.Value

                if( $value -eq "" ){
                    $info += "$key`n"
                } else{
                    $info += "$key = $value`n"
                }
            }
            $info += "`nRecommended value:`n"
            $info += "$($handler.getInfoPolicy( $registrypath ).recommendedvalue)`n"

            $policyname.text = $displayname
            $policyinfo.text = $info
            $currentvalue.text = $cvalue
        }
    })

    $updatepolicybutton.Add_Click({
        $policy = $securityoptionsview.SelectedItems[0]
        $value = $newvalue.text
        if( $policy -ne $null -or $value -eq "" ){
            $registrypath = $policy.tag
            $result = $handler.updatePolicy( $registrypath, $value)
            if( $result -eq $false ){
                [System.Windows.MessageBox]::Show( "Failed to update policy with the new value`nPolicy = $($policy.content.displayname)`nValue = $value" )
            }
            Reset-SecurityOptionsView
            Clear-Controls
        }
    })

    $window.Add_SizeChanged({
        $currentvalue.Set_FontSize( $window.actualheight / 15 )
        $newvalue.Set_FontSize( $window.actualheight / 15 )
        $policyname.Set_FontSize( $window.actualheight / 35 )
        $policyinfo.Set_FontSize( $window.actualheight / 30 )
    })

    Reset-SecurityOptionsView
    [void] $window.ShowDialog()
}

Show-SecurityOptions
