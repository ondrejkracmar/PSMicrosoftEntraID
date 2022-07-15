class ValidIdentityException: System.Exception {
    ValidIdentityException([string] $identityException) :
    base ((Get-PSFLocalizedString -Module PSAzureADDirectory -Name ValidIdentityException) -f $identityException) {}
}