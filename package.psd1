@{
    Root = 'c:\Projects\PSModules\PSMicrosoftEntraID\src\PSMicrosoftEntraID\functions\license\Enable-PSEntraIDUserLicenseServicePlan.ps1'
    OutputPath = 'c:\Projects\PSModules\PSMicrosoftEntraID\out'
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
        