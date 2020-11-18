function New-Share{
    param(
        [Alias("Name")] [String] $shareName,
        [Alias("Path")] [String] $sharePath,
        [Alias("Description")] [String] $shareDescription )
    if( (Get-SMBShare -Name $shareName -ErrorAction SilentlyContinue) -ne $null ){
        throw "Share already exist`n"
    }
    elseif( (Get-Item -Path $sharePath -ErrorAction SilentlyContinue) -eq $null ){
        throw "Path does not exist`n"
    }
    else {
        New-SMBShare -Name $shareName -Path $sharePath -Description $shareDescription
    }
}

function Remove-Share{
    param( [Alias("Name")] [String] $shareName )
    if( (Get-SMBShare -Name $shareName -ErrorAction SilentlyContinue) -eq $null ){
        throw "Share does not exist`n"
    } else {
        Remove-SMBShare -Name $shareName -Force
    }
}

function Set-Share{
    param(
        [Alias("Name")] [String] $shareName,
        [Alias("Description")] [String] $shareDescription )
    if( (Get-SMBShare -Name $shareName -ErrorAction SilentlyContinue) -eq $null ){
        throw "Share does not exist`n"
    } else {
        Set-SMBShare -Name $shareName -Description $shareDescription -Force
    }
}
