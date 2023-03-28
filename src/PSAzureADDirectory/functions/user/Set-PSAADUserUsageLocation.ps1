function Set-PSAADUserUsageLocation {
    <#
    .SYNOPSIS
        Get the properties of the specified user.
                
    .DESCRIPTION
        Get the properties of the specified user.
                
    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.
    
    .PARAMETER UsageLocationCode
        Azure Active Directory UsageLocation Code.
    
    .PARAMETER UsageLocationCountry
        The name of the country corresponding to its usagelocation.

    
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType('PSAzureADDirectory.User')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentityUsageLocationCode')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCode')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCountry')]
        [ValidateIdentity()]
        [string[]]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'IdentityUsageLocationCode')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocationCode,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCountry')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocationCountry,
        [switch]
        $EnableException
    )
     
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
    }
    
    process {
        foreach ($user in $Identity) {
            switch ($PSCmdlet.ParameterSetName) { 
                'IdentityUsageLocationCode' { 
                    $aADUser = Get-PSAADUser -Identity $user
                    if (-not ([object]::Equals($aADUser, $null))) {
                        $path = ("users/{0}" -f $aADUser.Id)
                    }
                    $usgaeLocationTarget = $usageLocationCode
                    $body = @{
                        usageLocation = $usageLocationCode
                    }
                }
                'IdentityUsageLocationCountry' { 
                    $aADUser = Get-PSAADUser -Identity $user
                    if (-not ([object]::Equals($aADUser, $null))) {
                        $path = ("users/{0}" -f $aADUser.Id)
                    }
                    $usgaeLocationTarget = (Get-UserUsageLocation)[$UsageLocationCountry]
                    $body = @{
                        usageLocation = (Get-UserUsageLocation)[$UsageLocationCountry]
                    }
                }
            }
            Invoke-PSFProtectedCommand -ActionString 'User.UsageLocation' -ActionStringValues $usgaeLocationTarget -Target $Identity -ScriptBlock {
                Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Patch
            } -EnableException $EnableException -PSCmdlet $PSCmdlet | ConvertFrom-RestUser
            if (Test-PSFFunctionInterrupt) { return }
        }
    }
    end {}
}