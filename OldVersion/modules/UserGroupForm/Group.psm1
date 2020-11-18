
function Search-Group{
    param( [String] $groupName )
    if( $groupName -eq "" ){ return -1 }
    elseif( (Get-LocalGroup $groupName -ErrorAction SilentlyContinue) -eq $null ){ return 0 }
    else{ return 1 }
}

function New-Group{
    param( [String] $group, [String] $description = "" )
    $group = $group.trim()
    try{
        New-LocalGroup -Name $group -Description $description -ErrorAction Stop > $null
    } catch {
        throw ("{0} group already exists." -f $group)
    }
}

function Remove-Group{
    param( [String] $group )
    $group = $group.trim()
    try{
        Remove-LocalGroup -Name $group -ErrorAction Stop > $null
    } catch {
        throw ("{0} group does not exist." -f $group)
    }
}

function rename-groups{
    param( [String]$old_name, [String]$new_name )
    try{
        Rename-LocalGroup -Name $old_name -NewName $new_name -ErrorAction Stop > $null
    } catch {
        throw ("{0} group does not exist or {1} group already exist." -f $old_name, $new_name)
    }
}
