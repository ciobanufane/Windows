
function Search-User{
    param( [String] $username )
    if( $username -eq "" ){ return -1 }
    elseif( (Get-LocalUser $username -ErrorAction SilentlyContinue) -eq $null ){ return 0 }
    else{ return 1 }
}

function Add-User{
    param( [String] $user )
    $user = $user.trim();
    try{
        $password=(Read-Host -prompt "Enter a password for $user" -AsSecureString);
        New-LocalUser -Name $user -Password $password > $null
    } catch {
        throw ("{0} already exist" -f $user)
    }
}

function Remove-User{
    param( [String] $user )
    $user = $user.trim()
    try{
        Remove-LocalUser $user -ErrorAction Stop
    } catch {
        throw ("{0} does not exist" -f $user)
    }
}

function Rename-User{
    param( [String]$old_name, [String]$new_name )
    $old_name = $old_name.trim()
    $new_name = $new_name.trim()
    try{
        Rename-LocalUser -name $old_name -newname $new_name -ErrorAction Stop > $null
    } catch {
        throw ("Either {0} does not exist or {1} already exist" -f $old_name, $new_name )
    }
}
