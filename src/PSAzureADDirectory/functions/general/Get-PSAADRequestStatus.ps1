function Get-PSAADRequestStatus
{
    [CmdletBinding(DefaultParametersetName="Token")]    
    param(
        [Parameter(ParameterSetName="Header", Mandatory=$false, Position=0)]
        [psobject]$RespopnseData)
    
    process {
        try{
            $childPathdUrl = $responseData.Headers.Location
            $authorizationToken = Receive-PSMTAuthorizationToken
            $NUMBER_OF_RETRIES = (Get-PSFConfig -FullName PSOffice365Reports.Settings.InvokeRestMethodRetryCount)
            $RETRY_TIME_SEC = (Get-PSFConfig -FullName PSOffice365Reports.Settings.InvokeRestMethodRetryTimeSec)
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath $childPathdUrl
            $responseStatus = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Bearer $authorizationToken"} -Method Get -ContentType "application/json"  -MaximumRetryCount $NUMBER_OF_RETRIES -RetryIntervalSec $RETRY_TIME_SEC -ErrorVariable responseError -ResponseHeadersVariable responseHeaders
            return $responseStatus
        }
        catch{
            Stop-PSFFunction -Message "Failed to delete data from $childPathdUrl." -ErrorRecord $_
        }
    }
}