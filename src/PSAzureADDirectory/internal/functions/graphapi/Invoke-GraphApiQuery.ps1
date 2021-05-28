Function Invoke-GraphApiQuery{
<#

#>
    [CmdletBinding(DefaultParametersetname="Default")]
    Param(
        [Parameter(Mandatory=$true,ParameterSetName='Default')]
        [string]$Uri,
        [Parameter(Mandatory=$false,ParameterSetName='Default')]
        [string]$Body,
        [Parameter(Mandatory=$true,ParameterSetName='Default')]
        [string]$AuthorizationToken,
        [Parameter(Mandatory=$false,ParameterSetName='Default')]
        [ValidateSet('Get','Post','Put','Patch','Delete','Merge')]
        [string]$Method = "Get",
        [string]$Accept = 'application/json',
        [string]$ContentType = 'application/json',
        [switch]$Status,
        [ValidateRange(5, 1000)]
        [int]$Top,
        [ValidateRange(1, [int]::MaxValue)]
        #[ValidateRange("Positive")]
        [int]$Skip,
        [switch]$Count,
        [string]$Filter,
        [string]$Select,
        [string]$Expand,
        [switch]$All
    )
    begin{
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $authHeader = @{
            'Accept'= $Accept
            'Content-Type'= $ContentType
            'Authorization'= $AuthorizationToken
        }
        $numberOFRetries = (Get-PSFConfigValue -FullName PSOffice365Reports.Settings.InvokeRestMethodRetryCount)
        $retryTimeSec = (Get-PSFConfigValue -FullName PSOffice365Reports.Settings.InvokeRestMethodRetryTimeSec)
    }

    process
    {
        if (Test-PSFFunctionInterrupt) { return }
        Try{ 
            if($Count.IsPresent) {
                $queryCount = ("`$count={0}" -f [System.Net.WebUtility]::UrlEncode($true)).ToLower()
            } 

            if(Test-PSFParameterBinding -Parameter Filter) {
                $queryFlter = "`$filter={0}" -f [System.Net.WebUtility]::UrlEncode($Filter)
            }

            if(Test-PSFParameterBinding -Parameter Select) {
                $querySelect = "`$select={0}" -f [System.Net.WebUtility]::UrlEncode($Select)
            }

            if(Test-PSFParameterBinding -Parameter Expand) {
                $queryExpand = "`$expand={0}" -f [System.Net.WebUtility]::UrlEncode($Expand)
            }

            if(Test-PSFParameterBinding -Parameter Format) {
                $queryFormat = "`$format={0}" -f [System.Net.WebUtility]::UrlEncode($Format)
            }
            
            if(Test-PSFParameterBinding -Parameter Top) {
                $queryTop = "`$top={0}" -f [System.Net.WebUtility]::UrlEncode($Top)
            }
            
            $queryString = (($queryCount, $queryTop, $queryFlter, $querySelect, $queryExpand, $queryFormat -ne $nul) -join "&")

            if([string]::IsNullOrEmpty($queryString)){
                $queryUri = $Uri
            }
            else {
                $queryUriString = "{0}?{1}"
                $queryUri =  $queryUriString -f $Uri,$queryString                
            }
            $queryParameters=@{
                Uri = $queryUri
                Method = $Method
                Headers = $authHeader
                ContentType = $ContentType
            }

            if(Test-PSFPowerShell -PSMinVersion '7.0.0'){
                $queryParameters['MaximumRetryCount'] = $numberOFRetries
                $queryParameters['RetryIntervalSec'] = $retryTimeSec
                $queryParameters['ErrorVariable'] = 'responseError'
                $queryParameters['ErrorAction'] = 'Stop'
                $queryParameters['ResponseHeadersVariable'] = 'responseHeaders'
            }

            If(Test-PSFParameterBinding -Parameter Body) {
                $queryParameters['Body'] = $Body
            }
            
            $response = Invoke-RestMethod @queryParameters
            $responseOutputList=[System.Collections.ArrayList]::new()
            if($response.PSobject.Properties.Name.Contains("value"))
            {
                [object[]]$responseOutput = $response.value
            }
            else {
                [object[]]$responseOutput =  $response
            }
            If(-not ($All.IsPresent) -and $response.PSobject.Properties.Name.Contains('@odata.nextLink')){
                Write-PSFMessage -Level Warning -String 'QueryMoreData'
                Start-Sleep 1
                [void]$responseOutputList.AddRange($responseOutput)
            }
            else {
                if($All.IsPresent){
                    $responseOutputList.AddRange($responseOutput)
                    while($response.PSobject.Properties.Name.Contains('@odata.nextLink'))
                    {
                        $nextURL = $response."@odata.nextLink"
                        $queryParameters['Uri'] = $nextURL
                        $queryParameters['ErrorAction'] = 'SilentlyContinue'
                        $response = Invoke-RestMethod @queryParameters

                        if($response.PSobject.Properties.Name.Contains("value")){
                            $responseOutput = $response.value
                        }
                        else {
                            $responseOutput =  $response
                        }
                        $responseOutputList.AddRange($responseOutput)
                    }
                }
                else{
                    $responseOutputList.AddRange($responseOutput)
                }
            }
            if((Test-PSFParameterBinding -Parameter Status) -and (Test-PSFPowerShell -PSMinVersion '7.0.0')){
                $responseHeaders
            }
            else {
                $responseOutputList
            }
            
        }
        Catch{
            Stop-PSFFunction -String 'FailedInvokeRest' -Target $queryUri -StringValues $Method, $queryUri -ErrorRecord $_ -SilentlyContinue
        }
        Write-PSFMessage -Level InternalComment -String 'QueryCommandOutput' -StringValues $queryUri -Target $queryUri -Tag GraphApi -Data $queryParameters
    }
}