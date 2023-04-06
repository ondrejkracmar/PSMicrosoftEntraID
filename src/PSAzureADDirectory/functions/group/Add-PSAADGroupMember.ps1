function Add-PSMTGroupMember {
    <#
    .SYNOPSIS
    Adds an owner or member to the team, and to the unified group which backs the team.
              
    .DESCRIPTION
        This cmdlet adds an owner or member to the team, and to the unified group which backs the team.
              
    .PARAMETER Groupd
        Id of Team (unified group)

    .PARAMETER UserId
        Id of User
    
    .PARAMETER Role
        user's role

    .PARAMETER Status
        Switch response header or result

#>
    [CmdletBinding(DefaultParameterSetName = 'AddSingleMember')]
    param(
        [Parameter(ParameterSetName = 'AddSingleMember', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'AddBulkMebers', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                }
                catch {
                    $false
                }
            })]
        [string]
        $GroupId,
        [Parameter(ParameterSetName = 'AddSingleMember', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                }
                catch {
                    $false
                }
            })]
        [Alias("Id")]
        [string]
        $UserId,
        [Parameter(ParameterSetName = 'AddSingleMember', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Member', 'Owner')]
        [string]
        $Role,
        [switch]
        $Status
    )
    
    begin {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "groups"
            $authorizationToken = Get-PSMTAuthorizationToken
            $graphApiParameters = @{
                Method             = 'Post'
                AuthorizationToken = "Bearer $authorizationToken"
                
            }
            #$property = Get-PSFConfigValue -FullName PSMicrosoftTeams.Settings.GraphApiQuery.Select.Group
        } 
        catch {
            Stop-PSFFunction -String 'StringAssemblyError' -StringValues $url -ErrorRecord $_
        }  
    }
    
    process {
        if (Test-PSFFunctionInterrupt) { return }                            
        if (Test-PSFParameterBinding -Parameter Role) {
            switch ($Role) {
                'Owner' {
                    $urlOwners = Join-UriPath -Uri $url -ChildPath "$($GroupId)/owners"
                    $graphApiParameters['Uri'] = Join-UriPath -Uri $urlOwners -ChildPath '$ref'
                    $bodyParameters = @{
                        "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "users/$($UserId)"
                    }
                }                
                'Member' {
                    $urlMembers = Join-UriPath -Uri $url -ChildPath "$($GroupId)/members"
                    $graphApiParameters['Uri'] = Join-UriPath -Uri $urlMembers -ChildPath '$ref'
                    $bodyParameters = @{
                        "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "directoryObjects('$($UserId)')"
                    }
                }
                Default {
                    $urlMembers = Join-UriPath -Uri $url -ChildPath "$($GroupId)/members"
                    $graphApiParameters['Uri'] = Join-UriPath -Uri $urlMembers -ChildPath '$ref'
                    $bodyParameters = @{
                        "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "directoryObjects('$($UserId)')"
                    }
                }
            }            
        }
        else {
            $urlMembers = Join-UriPath -Uri $url -ChildPath "$($GroupId)/members"
            $graphApiParameters['Uri'] = Join-UriPath -Uri $urlMembers -ChildPath '$ref'
            $bodyParameters = @{
                "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "directoryObjects('$($UserId)')"
            }
        }
        [string]$requestJSONQuery = $bodyParameters | ConvertTo-Json -Depth 10 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        $graphApiParameters['body'] = $requestJSONQuery
            
        If ($Status.IsPresent) {
            $graphApiParameters['Status'] = $true
        }
        Invoke-GraphApiQuery @graphApiParameters    
    }
	
    end {
	
    }
}