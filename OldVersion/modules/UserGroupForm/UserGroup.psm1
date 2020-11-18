function Add-LocalGroupMemberE{
    param( [String]$group, [String]$user )
    try{
        Add-LocalGroupMember -Group $group -Member $user -ErrorAction Stop
    } catch{
        $error_msg = ""
        if( (Get-LocalGroupMember -Group $group -Member $user) -ne $null ){
            $error_msg += ("Group '{0}' already contains user '{1}'.`n" -f $group,$user)
        }
        else{
            if( (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue) -eq $null ){
                $error_msg += ("Group '{0}' does not exist.`n" -f $group)
            }
            if( (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) -eq $null ){
                $error_msg += ("User '{0}' does not exist.`n" -f $user)
            }
        }
        throw $error_msg
    }
}
function Remove-LocalGroupMemberE{
    param( [String]$group, [String]$user )
    try{
        Remove-LocalGroupMember -Group $group -Member $user -ErrorAction Stop
    } catch{
        $error_msg = ""
        if( (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue) -eq $null ){
            $error_msg += Write-Host ("Group '{0}' does not exist.`n" -f $group)
        }
        if( (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) -eq $null ){
            $error_msg += Write-Host ("User '{0}' does not exist.`n" -f $user)
        }
        if( $error_msg -eq "" -and (Get-LocalGroupMember -Group $group -Member $user -ErrorAction SilentlyContinue) -eq $null ){
            $error_msg += ("Group '{0}' does not contain user '{1}'." -f $group,$user)
        }
        throw $error_msg
    }
}
