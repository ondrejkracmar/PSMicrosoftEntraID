function Get-PSEntraIDMessageCenter {
    <#
.SYNOPSIS
    Retrieves announcements from Microsoft 365 Message Center via Graph API using .NET deserialization.

.DESCRIPTION
    Queries Microsoft Graph API for service announcement messages, deserializes them using .NET and filters them by parameters.
    Uses Graph API $filter where supported (category, severity) and applies service and datetime filtering locally.
    Requires delegated Graph permission: ServiceMessage.Read.All.

.PARAMETER Service
    One or more Microsoft 365 services to filter messages by. Use 'All' to return all services (no filtering).

.PARAMETER Category
    Filters messages by category (feature, retire, stayInformed, planForChange).

.PARAMETER Severity
    Filters messages by severity (normal, high, critical).

.PARAMETER PublishedAfter
    Filters messages published after this UTC datetime (evaluated locally).

.PARAMETER PublishedBefore
    Filters messages published before this UTC datetime (evaluated locally).

.PARAMETER EnableException
    Enables throwing terminating exceptions if an error occurs during API call.

.EXAMPLE
    Get-PSEntraIDMessageCenter -Service "Microsoft Teams" -Category feature -PublishedAfter (Get-Date).AddDays(-7)

.EXAMPLE
    Get-PSEntraIDMessageCenter -Service All -Severity high

.OUTPUTS
    PSMicrosoftEntraID.MessageCenter.Message[]
#>
    [CmdletBinding()]
    [OutputType('PSMicrosoftEntraID.MessageCenter.Message[]')]
    param (
        [Parameter()]
        [ValidateSet(
            "All",
            "Azure Active Directory",
            "Bookings",
            "Copilot for Microsoft 365",
            "Defender for Endpoint",
            "Defender for Identity",
            "Defender for Office 365",
            "Dynamics 365 Apps",
            "Exchange Online",
            "Forms",
            "Intune",
            "Loop",
            "Microsoft 365 for the web",
            "Microsoft 365 suite",
            "Microsoft 365 Apps",
            "Microsoft Defender XDR",
            "Microsoft Entra",
            "Microsoft Fabric",
            "Microsoft Loop",
            "Microsoft Purview",
            "Microsoft Stream",
            "Microsoft Syntex",
            "Microsoft Teams",
            "OneDrive for Business",
            "Planner",
            "Power Apps",
            "Power Automate",
            "Power BI",
            "Project for the web",
            "Security & Compliance Center",
            "SharePoint Online",
            "Sway",
            "To Do",
            "Viva Engage",
            "Viva Insights",
            "Viva Learning",
            "Whiteboard",
            "Yammer Enterprise"
        )]
        [string[]] $Service,

        [Parameter()]
        [ValidateSet("feature", "retire", "stayInformed", "planForChange")]
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
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.MessageCenter.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.ServiceAnnouncement.Message).Value -join ',')
        }

        # Build Graph API-supported filters
        [string[]] $filterParts = @()

        if ($Category) {
            $categoryFilter = $Category | ForEach-Object { "category eq '$($_)'" }
            $filterParts += '(' + ($categoryFilter -join ' or ') + ')'
        }

        if ($Severity) {
            $severityFilter = $Severity | ForEach-Object { "severity eq '$($_)'" }
            $filterParts += '(' + ($severityFilter -join ' or ') + ')'
        }

        if ($filterParts.Count -gt 0) {
            $query['$filter'] = $filterParts -join ' and '
        }

        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [timespan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [bool] $cmdLetVerbose = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
    }

    process {
        Invoke-PSFProtectedCommand -ActionString 'MessageCenter.Get' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Office365.Platform) -ScriptBlock {
            if ($PublishedAfter -and $PublishedBefore -and ($PublishedAfter -gt $PublishedBefore)) {
                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name MessageCenter.Get.Validation) -f $PublishedBefore, $PublishedAfter)
                }
                [PSMicrosoftEntraID.ServiceAnnouncement.Message[]] $messageList = ConvertFrom-RestMessageCenter -InputObject (Invoke-EntraRequest `
                        -Service $serviceName `
                        -Path 'admin/serviceAnnouncement/messages' `
                        -Query $query `
                        -Method Get `
                        -Verbose:$cmdLetVerbose `
                        -ErrorAction Stop)

                # Local filter: Service
                if ($Service -and -not ($Service -contains 'All')) {
                    $messageList = $messageList | Where-Object {
                        $_.Services -and ($_.Services | Where-Object { $_ -in $Service }).Count -gt 0
                    }
                }

                # Local filter: PublishedAfter / PublishedBefore
                if ($PublishedAfter -or $PublishedBefore) {
                    $messageList = $messageList | Where-Object {
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
                    }
                }
                return $messageList#>

            } -EnableException:$EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait

            if (Test-PSFFunctionInterrupt) { return }
        }
    }
