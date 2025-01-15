Function Invoke-PSMicrosoftEntraIDBatchRequest {
    <#
    .SYNOPSIS
        Invokes an operation against Microsoft Entra ID batch requests.
    
    .DESCRIPTION
        This function receives an array of Request objects (from PSMicrosoftEntraID.Batch),
        potentially performs an action on them (you fill in the logic), and supports 
        user-friendly or exception-based error handling. It also respects ShouldProcess 
        for WhatIf/Confirm scenarios.
    
    .PARAMETER InputObject
        An array of Request objects to be processed.
    
    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions.
        This is less user friendly, but it allows catching exceptions in calling scripts.
    
    .PARAMETER Force
        The Force switch instructs the command to stop processing before any changes are made 
        and prompt for confirmation (depending on your logic in the code). 
        When used, you can step through changes to ensure only specific objects are modified.
    
    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.
    
    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing 
        before any changes are made. The command then prompts you to acknowledge each action 
        before it continues. This functionality is useful when you apply changes to many objects 
        and want precise control over the operation of the Shell.
    
    .EXAMPLE
        $req1 = [PSMicrosoftEntraID.Batch.Request]::new()
        $req1.Id = '1'
        $req1.Method = 'GET'
        $req1.Url = '/some/url'
    
        $req2 = [PSMicrosoftEntraID.Batch.Request]::new()
        $req2.Id = '2'
        $req2.Method = 'PATCH'
        $req2.Url = '/some/other/url'
    
        $requests = @($req1, $req2)
        Invoke-PSMicrosoftEntraIDBatchRequest -InputObject $requests -EnableException -Force -WhatIf
    
        # This example demonstrates calling the function with a set of Request objects,
        # enabling exceptions, forcing the operation, and using -WhatIf to simulate the process.
    
    #>
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
        [OutputType()]
        [CmdletBinding(
            SupportsShouldProcess = $true,    # enables -WhatIf and -Confirm
            ConfirmImpact = 'High'           # sets default confirmation impact
        )]
        Param(
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "An array of Request objects to be processed."
            )]
            [PSMicrosoftEntraID.Batch.Request[]]
            $InputObject,
            [switch]$EnableException,
            [switch]$Force
        )
    
        Begin {
            $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
            Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
            $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
            $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
            $path = '$batch'
            if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
                [bool]$cmdLetConfirm = $false
            }
            else {
                [bool]$cmdLetConfirm = $true
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
                [boolean]$cmdLetVerbose = $true
            }
            else{
                [boolean]$cmdLetVerbose =  $false
            }
        }
    
        Process {
            $body = @{}
            $body['requests'] = @()
            $body['requests'] = $body['requests'] + $InputObject
        }
    
        End {
            Invoke-PSFProtectedCommand -ActionString 'Batch.Invoke' -ActionStringValues ($InputObject.Id -join ",") -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                [void](Invoke-EntraRequest -Service $service -Path $path  -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }
    