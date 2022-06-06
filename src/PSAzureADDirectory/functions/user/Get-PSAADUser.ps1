﻿function Get-PSAADUser {
    <#
    .SYNOPSIS
        Get the properties of the specified user.
                
    .DESCRIPTION
        Get the properties of the specified user.
                
    .PARAMETER UserPrincipalName
        UserPrincipalName
#>
    [CmdletBinding(DefaultParameterSetName = 'FilterByName',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'FilterByUserPrincipalName')]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'FilterByName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromRemainingArguments = $false)]
        [switch]$All,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromRemainingArguments = $false)]
        [ValidateRange(5, 1000)]
        [int]$PageSize
    )
     
    begin {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "users"
            $authorizationToken = Get-PSAADAuthorizationToken
            $property = (Get-PSFConfig -Module PSAzureADDirectory -Name Settings.GraphApiQuery.Select.User).Value
        }
        catch {
            Stop-PSFFunction -String 'FailedGetUsers' -StringValues $graphApiParameters['Uri'] -ErrorRecord $_
        }
    }
    
    process {
        if (Test-PSFFunctionInterrupt) { return }
        $graphApiParameters = @{
            Method             = 'Get'
            AuthorizationToken = "Bearer $authorizationToken"
            Select = $property -join ","
        }

        if (Test-PSFParameterBinding -Parameter UserPrincipalName) {
            $urlUser = Join-UriPath -Uri $url -ChildPath $UserPrincipalName
            $graphApiParameters['Uri'] = $urlUser            
        }
        else {
            $graphApiParameters['Uri'] = $url
        }

        if (Test-PSFParameterBinding -Parameter Name) {
            $graphApiParameters['Filter'] = ("startswith(displayName,'{0}') or startswith(givenName,'{0}') or startswith(surname,'{0}') or startswith(mail,'{0}') or startswith(userPrincipalName,'{0}')" -f $Name)
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

        $userResult = Invoke-GraphApiQuery @graphApiParameters
        $userResult | Select-PSFObject -Property $property -ExcludeProperty '@odata*' -TypeName "PSAzureADDirectory.User"
    }    
}