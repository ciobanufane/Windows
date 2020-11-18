
<#
    function Get-SIDtoName{

        $hashtable = @{ }

        $users = Get-WMIObject -class win32_useraccount
        $groups = Get-WMIObject -class win32_group
        $system = Get-WMIObject -class win32_systemaccount

        foreach( $user in $users ){ $hashtable.add( $user.sid, $user.name ) }
        foreach( $group in $groups ){ $hashtable.add( $group.sid, $group.name ) }
        foreach( $sysaccount in $system ){ $hashtable.add( $sysaccount.sid, $sysaccount.name ) }

        return $hashtable

    }
#>

function Convert-NametoSID{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias("Name")]
        [String] $targetname
    )

    try{
        $objUser = New-Object System.Security.Principal.NTAccount($targetname)
        $objSID = $objUser.translate( [System.Security.Principal.SecurityIdentifier] )
        return $objSID.value
    } catch {
        Write-Error -Message "Cannot identify $targetname"
        return $null
    }
}

function Convert-SIDtoName{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias("SID")]
        [String] $targetsid
    )

    try{
        $objSID = New-Object System.Security.Principal.SecurityIdentifier($targetsid)
        $objUser = $objSID.translate( [System.Security.Principal.NTAccount] )
        return $objUser.value
    } catch {
        Write-Error -Message "Cannot identify $targetsid"
        return $null
    }
}

function Get-UserRights{

    $policylist = [System.Collections.ArrayList]@( )
    $lookuptable = @{ }
    $id = 0

    if( (Test-Path -Path ".\readur.inf") -eq $true ){
        Remove-Item -Path ".\readur.inf" -Force
    }

    secedit /export /areas USER_RIGHTS /cfg readur.inf > $null

    $file = Get-Content -Path "readur.inf" -Raw
    (Get-Item ".\readur.inf").Attributes += "Hidden"

    $pattern = "(?smi)\[Privilege Rights\](.*?)(^\[|^[\s]*$)"
    $policies = [regex]::match( $file, $pattern ).groups[1].value
    $policies = $policies -split "`n"

    foreach( $policy in $policies ){
        $policy = $policy.trim()
        if( $policy -ne "" ){
            $constname, $cvalue = $policy -split "="
            $cvalue =  ( $cvalue -split ","  |
                ForEach-Object{ $val = $_.trim()
                    if( $val[0] -eq "*" ){ (Convert-SIDtoName $val.substring(1)) -replace "BUILTIN\\","" -replace "NT AUTHORITY\\","" }
                    else { $val }
                }
             ) -join ", "
            $lookuptable.add( $constname.trim(), $id++ )
            [void] $policylist.add( @{ "constname" = $constname.trim(); "currentvalue" = $cvalue } )
        }
    }

    Remove-Item -Path ".\readur.inf" -Force

    $URI = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTVkcq6ZsJrsaUAtkzxGKdfXeRepQFW9uWRcrOUlePA8SrhtlzYvS8IiTzRQlrPxhp6lz9YMiAy4QUN/pub?gid=0&single=true&output=csv"

    if( (Test-Path -Path ".\ur.csv") -eq $false ){
        $request = Invoke-WebRequest -URI $URI
        $request.content > ".\ur.csv"
        (Get-Item ".\ur.csv").attributes += "Hidden"
    }

    $policies = Import-CSV -Path ".\ur.csv"

    foreach( $policy in $policies ){
        if( $lookuptable.containskey( $policy.constantname ) ){
            $index = $lookuptable[ $policy.constantname ]
            $policylist[ $index ].add( "displayname", $policy.displayname )
            $policylist[ $index ].add( "recommendedvalue", $policy.recommendedvalue )
            $policylist[ $index ] = [PSCustomObject] $policylist[ $index ]
        } else {
            $lookuptable.add( $policy.constantname, $id++ )
            [void] $policylist.add( @{ "constname" = $policy.constantname; "currentvalue" = ""; "displayname" = $policy.displayname; "recommendedvalue" = $policy.recommendedvalue } )
            $policylist[ $policylist.count-1 ] = [PSCustomObject] $policylist[  $policylist.count-1 ]
        }
    }

    return $policylist

}

function Add-NameToUserRights{
    param(
        [Parameter(Mandatory=$true)]
        [ref] $policylistref,
        [Parameter(Mandatory=$true)]
        [String] $constname,
        [Parameter(Mandatory=$true)]
        [String] $name
    )

    $policylist = $policylistref.value

    $index = 0..($policylist.count-1) | Where-Object{ $policylist[ $_ ].constname -eq $constname }
    if( $index -eq $null ){
        return @{ "message" = "could not find policy constant name: $constname"; "status" = $false }
    }

    $namelist = $policylist[ $index ].currentvalue -split ","
    if( (Convert-NameToSID -Name $name -ErrorAction SilentlyContinue) -eq $null ){
        return @{ "message" = "could not find the SID of $name"; "status" = $false }
    }
    elseif( $namelist -contains $name ){
        return @{ "message" = "policy already contains user: $name"; "status" = $false }
    }

    $policylist[ $index ].currentvalue = $policylist[ $index ].currentvalue + ", " + $name
    return @{ "message" = "success"; "status" = $true }

}

function Remove-NameFromUserRights{
    param(
        [Parameter(Mandatory=$true)]
        [ref] $policylistref,
        [Parameter(Mandatory=$true)]
        [String] $constname,
        [Parameter(Mandatory=$true)]
        [String] $name
    )

    $policylist = $policylistref.value

    $index = 0..($policylist.count-1) | Where-Object{ $policylist[ $_ ].constname -eq $constname }
    if( $index -eq $null ){ return $false }

    $namelist = $policylist[ $index ].currentvalue -split ","
    if( -not $namelist -contains $name ){ return $false }

    $policylist[ $index ].currentvalue = ($namelist | Where-Object { $_ -ne $name }) -join ", "
    return $true

}

function Update-UserRights{

    param(
        [Parameter(Mandatory=$true)]
        [ref] $policylistref
    )

    if( (Test-Path -Path ".\writeur.inf") -eq $true ){
        Remove-Item -Path ".\writeur.inf" -Force
    }

    if( (Test-Path -Path "readur.inf") -eq $false ){
        secedit /export /areas USER_RIGHTS /cfg readur.inf > $null
        (Get-Item ".\readur.inf").Attributes += "Hidden"
    }

    New-Item -Path ".\writeur.inf" > $null
    (Get-Item ".\writeur.inf").Attributes += "Hidden"

    $file = Get-Content -Path "readur.inf" -Raw
    $pattern = "(?smi)(\[Unicode\].*?)(^\[|^[\s]*$)"
    $unicode = [regex]::match( $file, $pattern ).groups[1].value

    $pattern = "(?smi)(\[Version\].*?)(^\[|^[\s]*$)"
    $version = [regex]::match( $file, $pattern ).groups[1].value

    $rights = "[Privilege Rights]`n"
    $policylist = $policylist.value
    $policylist | ForEach-Object{
        $policy = $_
        $constname = $policy.constname
        $cvalue = $policy.currentvalue
        if( $cvalue -ne "" ){
            $value = @($cvalue -split "," | ForEach-Object{ "*$(Convert-NameToSID -Name $_.trim())" }) -join ","
            $rights += "$constname = $value`n"
        }
    }

    [System.IO.File]::AppendAllText( ".\writeur.inf", $unicode, [System.Text.Encoding]::Unicode )
    [System.IO.File]::AppendAllText( ".\writeur.inf", $version, [System.Text.Encoding]::Unicode )
    [System.IO.File]::AppendAllText( ".\writeur.inf", $rights,  [System.Text.Encoding]::Unicode )

    secedit /configure /areas USER_RIGHTS /db "C:\windows\security\local.sdb" /cfg ".\writeur.inf" > $null

    Remove-Item -Path ".\writeur.inf" -Force
    Remove-Item -Path ".\readur.inf" -Force

}
