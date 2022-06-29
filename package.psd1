@{
    Root = 'c:\Projects\PSModules\PSAzureADDirectory\src\PSAzureADDirectory\functions\license\Enable-PSAADUserLicenseServicePlan.ps1'
    OutputPath = 'c:\Projects\PSModules\PSAzureADDirectory\out'
    Package = @{
        Enabled = $true
        Obfuscate = $false
        HideConsoleWindow = $false
        DotNetVersion = 'v4.6.2'
        FileVersion = '1.0.0'
        FileDescription = ''
        ProductName = ''
        ProductVersion = ''
        Copyright = ''
        RequireElevation = $false
        ApplicationIconPath = ''
        PackageType = 'Console'
    }
    Bundle = @{
        Enabled = $true
        Modules = $true
        # IgnoredModules = @()
    }
}
        