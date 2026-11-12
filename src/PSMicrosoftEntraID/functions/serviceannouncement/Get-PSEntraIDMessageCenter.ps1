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

    Returns Microsoft Teams feature announcements published in the last 7 days.

.EXAMPLE
    Get-PSEntraIDMessageCenter -Service All -Severity high

    Returns all high severity Message Center announcements across all services.

.OUTPUTS
    PSMicrosoftEntraID.MessageCenter.Message[]
    .NOTES
        Piping into Select-Object -First N logs a warning that is not a failure:

            WARNING: [<cmdlet>] Failed to: ... | The pipeline has been stopped

        The results are correct and complete. Select-Object stops the pipeline once it
        has what it asked for, and the next write throws PipelineStoppedException -
        normal termination, reported as an error only because the write happens inside a
        protected block. Materialise first if the warning is in the way:

            $items = @(<cmdlet> ...)
            $items | Select-Object -First 3

        or filter server-side with -Filter instead of trimming client-side. Not silenced
        on purpose: the only fix that works is to collect the whole result before
        emitting any of it, which would cost streaming on every read.

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
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
                        -ErrorAction Stop)

                # Local filter: Service
                if ($Service -and -not ($Service -contains 'All')) {
                    $messageList = $messageList | Where-Object {
                        $_.Services -and ($_.Services | Where-Object { $_ -in $Service }).Count -gt 0
                    }
                }

                # Local filter: PublishedAfter / PublishedBefore
                # StartDateTime is a DateTime (UTC) now - no string parsing. A bound
                # value of Kind Local (Get-Date) is moved to UTC so both sides of the
                # comparison mean the same instant; Unspecified is taken as UTC, as
                # the help says.
                if ($PublishedAfter -or $PublishedBefore) {
                    $after = if ($PublishedAfter -and $PublishedAfter.Kind -eq [System.DateTimeKind]::Local) { $PublishedAfter.ToUniversalTime() } else { $PublishedAfter }
                    $before = if ($PublishedBefore -and $PublishedBefore.Kind -eq [System.DateTimeKind]::Local) { $PublishedBefore.ToUniversalTime() } else { $PublishedBefore }
                    $messageList = $messageList | Where-Object {
                        if ($null -eq $_.StartDateTime) { return $false }
                        $published = $_.StartDateTime
                        if ($published.Kind -eq [System.DateTimeKind]::Local) { $published = $published.ToUniversalTime() }
                        (-not $after -or $published -ge $after) -and
                        (-not $before -or $published -le $before)
                    }
                }
                return $messageList

            } -EnableException:$EnableException -Continue -PSCmdlet $PSCmdlet -WhatIf:$false
            if (Test-PSFFunctionInterrupt) { return }
        }
    }
