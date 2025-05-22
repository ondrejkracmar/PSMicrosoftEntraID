function Get-PSEntraIDMessageCenter {
    <#
.SYNOPSIS
    Retrieves announcements from Microsoft 365 Message Center via Graph API using .NET deserialization.

.DESCRIPTION
    Queries Microsoft Graph API for service announcement messages, deserializes them using .NET and filters them by parameters.
    Requires delegated Graph permission: ServiceMessage.Read.All.

.PARAMETER Service
    One or more Microsoft 365 services to filter messages by. Must match known values (e.g. 'Exchange Online').

.PARAMETER Category
    Filters messages by category (plan, feature, retire, stayInformed).

.PARAMETER Severity
    Filters messages by severity (normal, high, critical).

.PARAMETER PublishedAfter
    Filters messages published after this UTC datetime.

.PARAMETER PublishedBefore
    Filters messages published before this UTC datetime.

.PARAMETER EnableException
    Enables throwing terminating exceptions.

.EXAMPLE
    Get-PSEntraIDMessageCenter -Service "Purview", "Teams" -PublishedAfter (Get-Date).AddDays(-30)

.OUTPUTS
    PSMicrosoftEntraID.MessageCenter.Message[]
#>
    [CmdletBinding()]
    [OutputType('PSMicrosoftEntraID.MessageCenter.Message[]')]
    param (
        [Parameter()]
        [ValidateSet(
            "Azure Active Directory",
            "Bookings",
            "Defender for Endpoint",
            "Defender for Identity",
            "Defender for Office 365",
            "Dynamics 365 Apps",
            "Exchange Online",
            "Forms",
            "Intune",
            "Loop",
            "Microsoft 365 Apps",
            "Microsoft Defender XDR",
            "Microsoft Entra",
            "Microsoft Fabric",
            "Microsoft Teams",
            "OneDrive for Business",
            "Planner",
            "Power Apps",
            "Power Automate",
            "Power BI",
            "Project for the web",
            "Purview",
            "Security & Compliance Center",
            "SharePoint Online",
            "Stream",
            "Sway",
            "To Do",
            "Viva Insights",
            "Viva Learning",
            "Whiteboard",
            "Yammer Enterprise"
        )]
        [string[]] $Service,

        [Parameter()]
        [ValidateSet("plan", "feature", "retire", "stayInformed", "planForChange")]
        [string[]] $Category,

        [Parameter()]
        [ValidateSet("normal", "high", "critical")]
        [string[]] $Severity,

        [Parameter()]
        [datetime] $PublishedAfter,

        [Parameter()]
        [datetime] $PublishedBefore,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $serviceName = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $serviceName -Cmdlet $PSCmdlet

        [hashtable] $query = @{
            '$count' = 'true'
            '$top'   = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.ServiceAnnouncement.Message).Value -join ',')
        }

        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [timespan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [bool] $cmdLetVerbose = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
    }

    process {
        Invoke-PSFProtectedCommand -ActionString 'MessageCenter.Get' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Office365.Platform) -ScriptBlock {

            [PSMicrosoftEntraID.ServiceAnnouncement.Message[]] $messageList = ConvertFrom-RestMessageCenter -InputObject (Invoke-EntraRequest `
                    -Service $serviceName `
                    -Path 'admin/serviceAnnouncement/messages' `
                    -Query $query `
                    -Method Get `
                    -Verbose:$cmdLetVerbose `
                    -ErrorAction Stop)

            $filtered = $messageList | Where-Object {
                (
                    -not $Service -or
        ($_.Services -and ($_.Services | Where-Object { $Service -contains $_ }).Count -gt 0)
                ) -and
                (
                    -not $Category -or
        ($Category -contains $_.Category)
                ) -and
                (
                    -not $Severity -or
        ($Severity -contains $_.Severity)
                ) -and
                (
                    -not $_.PublishedDateTime -or (& {
                            try {
                                $published = [datetime]::Parse($_.PublishedDateTime)
                                (
                    (-not $PublishedAfter -or $published -ge $PublishedAfter) -and
                    (-not $PublishedBefore -or $published -le $PublishedBefore)
                                )
                            }
                            catch {
                                $false
                            }
                        })
                )
            }

            return $filtered

        } -EnableException:$EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
}
