<#
    Grabs an online CSV file containing information about Security Options and stores the text content in a file
#>
function Get-SecurityOptionsInfo{
    if( (Test-Path ".\securityoptions.csv") -eq $false ){
        $request = Invoke-WebRequest -URI "https://docs.google.com/spreadsheets/d/e/2PACX-1vTVkcq6ZsJrsaUAtkzxGKdfXeRepQFW9uWRcrOUlePA8SrhtlzYvS8IiTzRQlrPxhp6lz9YMiAy4QUN/pub?gid=508321539&single=true&output=csv"
        $request.content > "securityoptions.csv"
    }
}

function Get-CurrentSecurityOptions{
    secedit /export /cfg "securityoptions.inf" /areas SECURITYPOLICY > $null

    $file = Get-Content -path "securityoptions.inf" -Raw
    $pattern = "(?smi)\[Registry Values\](.*)(\[)?"
    $policies = [regex]::match( $file, $pattern ).groups[1].value

    $policies = $policies -split "`n"
    $resultObject = @{ }
    foreach( $policy in $policies ){
        $policy = $policy.trim()
        if( -not $policy -eq "" ){
            $registrypath = ($policy -split "=")[0].trim()
            $currentvalue = ($policy -split "=")[1].trim()
            $resultObject.add( $registrypath, $currentvalue )
        }
    }
    return $resultObject
}

<#
    Used for parsing the security options csv file
    Returns a hashtable containing each policy
#>
function Import-SecurityOptions{

    $policies = Import-CSV -path "securityoptions.csv"

    $result = @{ }

    foreach( $policy in $policies ){
        <#
            Policy includes RegistryPath, DisplayName, PossibleValues, DefaultValue, RecommendedValues, and Explanation

            PossibleValues can have multiple values; each value is separated by a new line
            Ignores any policies with N/A as RegistryPath
            Ignores any policies with IGNORE as PossibleValues
        #>

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
                "defaultvalue" = $policy.defaultvalue
                "recommendedvalues" = $policy.recommendedvalues
                "format" = $format
            }

            [void] $result.add( $policy.registrypath, $value )
        }
    }
    return $result
}

function Update-Policy{
    param(
        [Parameter(Mandatory=$true)]
        [String] $path,
        [Parameter(Mandatory=$true)]
        [String] $value,
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$possiblevalues
    )

    $pattern = "(.*)\\(.*)"
    $match = [regex]::match( $path, $pattern )

    $registry = $match.groups[1].value
    $property = $match.groups[2].value

    <#
        Checking for values with a range
        Checking for values that accepts any string
        Checking for values with fixed values
    #>
    if( $possiblevalues.count -eq 1 -and $possiblevalues[0] -like "*-*" ){
        $min,$max = $possiblevalues[0] -split "-"
        if( $value -ge $min -and $value -le $max ){
            Write-RegistryValue -path $registry -property $property -value $value
            return $true
        }
    }
    elseif( $possiblevalues.count -eq 1 -and $possiblevalues[0] -eq "any string"){
        Write-RegistryValue -path $registry -property $property -value $value
        return $true
    }
    elseif ( $possiblevalues -contains $value ){
        Write-RegistryValue -path $registry -property $property -value $value
        return $true
    }
    return $false
}

function Write-RegistryValue{
    param(
        [Parameter(Mandatory=$true)]
        [String] $path,
        [Parameter(Mandatory=$true)]
        [String] $property,
        [Parameter(Mandatory=$true)]
        [String] $value
    )
    $reg = Get-ItemProperty -path $path -name $property -ErrorAction SilentlyContinue
    if( $reg -eq $null){
        #New-ItemProperty -path $registrypath -name $property -value $value
    } else {
        #Set-ItemProperty -path $registrypath -name $property -value $value
    }
}
