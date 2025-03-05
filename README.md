# PSMicrosoftEntraID

PSMicrosoftEntraID is a PowerShell module that simplifies management and automation tasks in Microsoft Entra ID (formerly known as Azure Active Directory). It provides a suite of cmdlets for user and license management, as well as support for batch processing of operations.

## Features

- **User Management:** Retrieve and manage users within your Microsoft Entra ID tenant.
- **License Management:** Easily enable or disable user licenses.
- **Batch Processing:** Create batch request objects for deferred execution using the `-PassThru` parameter.
- **Robust Error Handling:** Built-in error handling with options for retry mechanisms.

## Prerequisites

- PowerShell **7.x or later** (PowerShell 5.1 is **not supported**)
- The **PSFramework** module (required dependency)
- A valid Microsoft Entra ID tenant and the necessary permissions to manage users and licenses

## Installation

First, install the required **PSFramework** module:

```powershell
Install-Module -Name PSFramework -Scope CurrentUser
```

Then, install the **PSMicrosoftEntraID** module:

```powershell
Install-Module -Name PSMicrosoftEntraID -Scope CurrentUser
```

Or import it into your current session:

```powershell
Import-Module PSMicrosoftEntraID
```

## Usage Examples

### Disable a User License

To disable a license for a user:

```powershell
Disable-PSEntraIDUserLicense -Identity user@contoso.com -SkuPartNumber ENTERPRISEPACK
```

### Create a Batch Request Object

If you want to defer the execution of the license disable action (for example, to process multiple requests together), use the `-PassThru` parameter to create a batch request object:

```powershell
$batchRequest = Disable-PSEntraIDUserLicense -Identity user@contoso.com -SkuPartNumber ENTERPRISEPACK -PassThru
```

This command returns an object of type `PSMicrosoftEntraID.Batch.Request` that can be passed to another cmdlet for batch processing.

## Getting Help

For detailed information on any cmdlet, use the `Get-Help` command:

```powershell
Get-Help Disable-PSEntraIDUserLicense -Full
```

## Contributing

Contributions are welcome! If you encounter any issues or would like to add features, please open an issue or submit a pull request on the project's repository.

## License

This project is licensed under the [MIT License](LICENSE).
