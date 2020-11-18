
<# TODO: replace all create files with temporary files #>

class PolicyHandler{

    [System.Collections.Hashtable] $current = @{ }
    [System.Collections.Hashtable] $info = @{ }
    [String] $uri
    [String] $filename
    [String] $area

    PolicyHandler( [String] $uri, [String] $filename, [String] $area ){
        $this.uri = $uri
        $this.filename = $filename
        $this.area = $area
    }

    [void] requestInfoPolicies(){
        if( (Test-Path -Path "$($this.filename).csv" ) -eq  $false ){
            $request = Invoke-WebRequest -uri $this.uri
            $request.content > "$($this.filename).csv"
            (Get-Item "$($this.filename).csv").Attributes += "Hidden"
        }
    }

    [void] getInfoPolicies(){

        $this.info.Clear()
        $this.requestInfoPolicies()
        $policies = Import-CSV -Path "$($this.filename).csv"

        foreach( $policy in $policies ){
            if( $policy.constantname -eq "N/A" -or $policy.possiblevalues -eq "IGNORE"){
                continue
            } else {
                $possiblevalues = @{ }
                @( $policy.possiblevalues -split "`n" ) | ForEach-Object{
                    $value = @( $_ -split "=" )
                    $key = $value[0].trim()

                    if( $key -like "*,*" ){
                        $key = @($key -split ",")[1].trim()
                    }

                    if( $value.length -eq 1 ){
                        $possiblevalues.add( $key, "" )
                    } else {
                        $possiblevalues.add( $key, $value[1].trim() )
                    }
                }

                $value = [PSCustomObject]@{
                    "displayname" = $policy.displayName
                    "possiblevalues" = $possiblevalues
                    "recommendedvalue" = $policy.recommendedvalue
                }

                $this.info.add( $policy.constantname, $value )
            }
        }

    }

    [void] getCurrentPolicies(){
        $this.current.Clear()
        if( (Test-Path -Path "$($this.filename).inf" ) -eq $true ){
            Remove-Item -Path "$($this.filename).inf" -Force
        }

        secedit /export /cfg "$($this.filename).inf" /areas SECURITYPOLICY > $null
        (Get-Item "$($this.filename).inf").Attributes += "Hidden"

        $file = Get-Content -path "$($this.filename).inf" -Raw
        $pattern = "(?smi)\[$($this.area)\](.*?)(^\[|^[\s]*$)"
        $policies = [regex]::match( $file, $pattern ).groups[1].value
        $policies = $policies -split "`n"

        foreach( $policy in $policies ){
            $policy = $policy.trim()
            if( $policy -ne "" ){
                $constname, $cvalue = $policy -split "="
                $constname = $constname.trim(); $cvalue = $cvalue.trim()
                $this.current.add( $constname, $cvalue )
            }
        }

        Remove-Item -Path "$($this.filename).inf" -Force

    }

    [PSCustomObject] getInfoPolicy( [String] $constname ){
        if( $this.info.ContainsKey( $constname ) -ne $true ){
            return $null
        }

        return $this.info[ $constname ]
    }

    [String] getCurrentPolicy( [String] $constname ){
        if( $this.current.ContainsKey( $constname ) -ne $true ){
            return $null
        }

        if( $this.current[ $constname ] -like "*,*" ){
            return @($this.current[ $constname ] -split ",")[1] -replace "`"",""
        }

        return $this.current[ $constname ]
    }

    [boolean] updatePolicy( [String] $constname, [String] $value ){

        if( $this.verifyPolicyChange( $constname, $value ) -eq $false ){
            return $false
        }

        switch( $this.area ){
            "Registry Values" {
                $pattern = "(.*)\\(.*)"
                $match = [regex]::match( $constname, $pattern )

                $path = $match.groups[1].value -replace "MACHINE","HKLM:"
                $name = $match.groups[2].value

                $reg = Get-ItemProperty -path $path -name $name -ErrorAction SilentlyContinue
                if( $reg -eq $null){
                    New-ItemProperty -path $path -name $name -value $value
                } else {
                    Set-ItemProperty -path $path -name $name -value $value
                }
                return $true
            }
            "Event Audit" {
                $audittable = @{
                    "AuditSystemEvents" = "System"
                    "AuditLogonEvents" = "Logon/Logoff"
                    "AuditObjectAccess" = "Object Access"
                    "AuditPrivilegeUse" = "Privilege Use"
                    "AuditPolicyChange" = "Policy Change"
                    "AuditAccountManage" = "Account Management"
                    "AuditProcessTracking" = "Detailed Tracking"
                    "AuditDSAccess" = "DS Access"
                    "AuditAccountLogon" = "Account Logon"
                }
                $category = $audittable[ $constname ]
                switch( $value ){
                    "0" { auditpol /set /category:"$category" /success:disable /failure:disable; break }
                    "1" { auditpol /set /category:"$category" /success:enable /failure:disable; break }
                    "2" { auditpol /set /category:"$category" /success:disable /failure:enable; break }
                    "3" { auditpol /set /category:"$category" /success:enable /failure:enable; break }
                    default { return $false }
                }
                return $true
            }
            "System Access" {
                if( (Test-Path -Path ".\writesa.inf") -eq $true ){
                    Remove-Item -Path ".\writesa.inf" -Force
                }

                New-Item -Path ".\writesa.inf"
                (Get-Item ".\writesa.inf").Attributes += "Hidden"

                $file = Get-Content -Path "$($this.filename).inf" -Raw
                $pattern = "(?smi)(\[Unicode\].*?)(^\[|^[\s]*$)"
                $unicode = [regex]::match( $file, $pattern ).groups[1].value

                $pattern = "(?smi)(\[Version\].*?)(^\[|^[\s]*$)"
                $version = [regex]::match( $file, $pattern ).groups[1].value

                $pattern = "(?smi)(\[System Access\].*?)(^\[|^[\s]*$)"
                $system  = [regex]::match( $file, $pattern ).groups[1].value

                $cvalue = $this.current[ $constname ]
                $system = $system -replace "$constname = $cvalue", "$constname = $value"

                [System.IO.File]::AppendAllText( ".\writesa.inf", $unicode, [System.Text.Encoding]::Unicode )
                [System.IO.File]::AppendAllText( ".\writesa.inf", $version, [System.Text.Encoding]::Unicode )
                [System.IO.File]::AppendAllText( ".\writesa.inf", $system,  [System.Text.Encoding]::Unicode )

                secedit /configure /areas SECURITYPOLICY /db "C:\windows\security\local.sdb" /cfg ".\writesa.inf"

                Remove-Item -Path ".\writesa.inf" -Force
                return $true
            }
        }
        return $false
    }

    hidden [boolean] verifyPolicyChange( [String] $constname, [String] $value ){
        if( $this.info.ContainsKey( $constname) ){
            $possiblevalues = $this.info[ $constname ].possiblevalues.keys
            if( $possiblevalues.count -eq 1 -and $possiblevalues[0] -like "*-*" ){
                $min,$max = $possiblevalues[0] -split "-"
                $min = $min -as [int]
                $max = $max -as [int]
                $v = $value -as [int]
                if( $v -ge $min -and $v -le $max ){
                    return $true
                }
            } elseif( ($possiblevalues.count -eq 1 -and $possiblevalues[0] -eq "any string") -or $possiblevalues -contains $value ){
                return $true
            }
        }
        return $false
    }

}
