
class SecurityOptionsHandler{

    [System.Collections.Hashtable] $currentSO = @{ }
    [System.Collections.Hashtable] $infoSO = @{ }
    [String] $uri = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTVkcq6ZsJrsaUAtkzxGKdfXeRepQFW9uWRcrOUlePA8SrhtlzYvS8IiTzRQlrPxhp6lz9YMiAy4QUN/pub?gid=508321539&single=true&output=csv"
    [String] $csv = "securityoptions.csv"

    [void] requestInfoSecurityOptions(){
        if( (Test-Path $this.csv ) -eq $false ){
            $request = Invoke-WebRequest -URI $this.uri
            $request.content > $this.csv
        }
    }

    [void] getCurrentSecurityOptions(){

        $this.currentSo.Clear()

        secedit /export /cfg "securityoptions.inf" /areas SECURITYPOLICY > $null

        $file = Get-Content -path "securityoptions.inf" -Raw
        $pattern = "(?smi)\[Registry Values\](.*?)(^\[|^[\s]*$)"
        $policies = [regex]::match( $file, $pattern ).groups[1].value

        write-host $policies

        $policies = $policies -split "`n"

        foreach( $policy in $policies ){
            $policy = $policy.trim()
            if( $policy -ne "" ){
                $registrypath = ($policy -split "=")[0].trim()
                $currentvalue = ($policy -split "=")[1].trim()
                $this.currentSO.add( $registrypath, $currentvalue )
            }
        }
    }

    [void] getInfoSecurityOptions(){

        $this.infoSO.Clear()
        $policies = Import-CSV -path $this.csv

        <#
            Policy includes RegistryPath, DisplayName, PossibleValues, DefaultValue, RecommendedValues, and Explanation

            PossibleValues can have multiple values; each value is separated by a new line
            Ignores any policies with N/A as RegistryPath
            Ignores any policies with IGNORE as PossibleValues
        #>

        foreach( $policy in $policies ){
            if( $policy.registrypath -eq "N/A" -or $policy.possiblevalues -eq "IGNORE"){
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

                [void] $this.infoSO.add( $policy.registrypath, $value )
            }
        }
    }

    [PSCustomObject] getInfoPolicy( [String] $registrypath ){
        return $this.infoSO[ $registrypath ]
    }

    <#
        Returns the current value for a registry
        Registry Value has a format of X,Y where Y is the current value
    #>

    [String] getCurrentPolicy( [String] $registrypath){
        return @($this.currentSO[$registryPath] -split ",")[1] -replace "`"",""
    }

    [boolean] updatePolicy( [String] $registrypath, [String] $value ){
        $pattern = "(.*)\\(.*)"
        $match = [regex]::match( $registrypath, $pattern )

        $path = $match.groups[1].value -replace "MACHINE","HKLM:"
        $name = $match.groups[2].value
        $possiblevalues = $this.infoSO[$registrypath].possiblevalues.keys

        <#
            Checking for values with a range
            Checking for values that accepts any string
            Checking for values with fixed values
        #>

        if( $possiblevalues.count -eq 1 -and $possiblevalues[0] -like "*-*" ){
            $min,$max = $possiblevalues[0] -split "-"
            if( $value -ge $min -and $value -le $max ){
                $this.writeRegistryValue( $path, $name, $value )
                return $true
            }
        }
        elseif( $possiblevalues.count -eq 1 -and $possiblevalues[0] -eq "any string"){
            $this.writeRegistryValue( $path, $name, $value )
            return $true
        }
        elseif ( $possiblevalues -contains $value ){
            $this.writeRegistryValue( $path, $name, $value )
            return $true
        }
        return $false
    }

    hidden [void] writeRegistryValue( [String] $path, [String] $name, [String] $value ){
        $reg = Get-ItemProperty -path $path -name $name -ErrorAction SilentlyContinue
        if( $reg -eq $null){
            #New-ItemProperty -path $path -name $name -value $value
        } else {
            #Set-ItemProperty -path $path -name $name -value $value
        }
    }

}
