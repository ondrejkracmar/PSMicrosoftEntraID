function Get-PSAADGroup {
    [OutputType('PSAzureADDirectory.User.License')]
    [CmdletBinding(DefaultParameterSetName = 'GroupId')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'GroupId')]
        [ValidateIdentity()]
        [string]
        $GroupId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DisplayName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DisplayName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'MailNickName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $MailNickName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Public", "Private")]
        [string]
        $Visibility,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [switch]$All,
        [Parameter(Mandatory = $false, ParameterSetName = 'Visibility')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 999)]
        [int]
        $PageSize = 100
    )

    begin {
        
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = $PageSize
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Group).Value -join ',')
        }
        
    }
	
    process {
        if (Test-PSFFunctionInterrupt) { return }
        
        $graphApiParameters = @{
            Method             = 'Get'
            AuthorizationToken = "Bearer $authorizationToken"
            Uri                = $url
            Select             = $property -join ","
        }

        if (Test-PSFParameterBinding -Parameter GroupId) {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "groups/$($GroupId)"
            $graphApiParameters['Uri'] = $url
        }
			
        if (Test-PSFParameterBinding -Parameter MailNickName) {
            $graphApiParameters['Filter'] = '{0} {1}' -f $graphApiParameters['Filter'], ("startswith(mailNickName,'{0}')" -f $MailNickName)
        }
			
        if (Test-PSFParameterBinding -Parameter DisplayName) {
            $graphApiParameters['Filter'] = '{0} {1}' -f $graphApiParameters['Filter'], ("startswith(displayName,'{0}')" -f $DisplayName)
        }

        if (Test-PSFParameterBinding -Parameter Filter) {
            $graphApiParameters['Filter'] = $Filter
        }

        if (Test-PSFParameterBinding -Parameter All) {
            $graphApiParameters['All'] = $true
        }

        if (Test-PSFParameterBinding -Parameter PageSize) {
            $graphApiParameters['Top'] = $PageSize
        }
        $teamResult = Invoke-GraphApiQuery @graphApiParameters

        if (Test-PSFParameterBinding -Parameter Visibility) {
            $teamResult | Where-Object { $_.Visibility -eq $Visibility } | Select-PSFObject -Property $property -ExcludeProperty '@odata*' -TypeName 'PSMicrosoftTeams.Group'
        }
        else {
            $teamResult | Select-PSFObject -Property $property -ExcludeProperty '@odata*' -TypeName 'PSMicrosoftTeams.Group'	
        }
    }

    end {
    }

}