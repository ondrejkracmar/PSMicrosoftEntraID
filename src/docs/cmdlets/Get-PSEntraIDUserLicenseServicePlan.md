---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDUserLicenseServicePlan

## SYNOPSIS
Get users who are assigned licenses

## SYNTAX

### Identity (Default)
```
Get-PSEntraIDUserLicenseServicePlan -Identity <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ServicePlanNameCompanyName
```
Get-PSEntraIDUserLicenseServicePlan -CompanyName <String[]> -ServicePlanName <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ServicePlanIdCompanyName
```
Get-PSEntraIDUserLicenseServicePlan -CompanyName <String[]> -ServicePlanId <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### SkuPartNumberCompanyName
```
Get-PSEntraIDUserLicenseServicePlan -CompanyName <String[]> -SkuPartNumber <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### SkuIdCompanyName
```
Get-PSEntraIDUserLicenseServicePlan -CompanyName <String[]> -SkuId <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### CompanyName
```
Get-PSEntraIDUserLicenseServicePlan -CompanyName <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### SkuId
```
Get-PSEntraIDUserLicenseServicePlan -SkuId <String[]> [-EnableException] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### SkuPartNumber
```
Get-PSEntraIDUserLicenseServicePlan -SkuPartNumber <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ServicePlanId
```
Get-PSEntraIDUserLicenseServicePlan -ServicePlanId <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ServicePlanName
```
Get-PSEntraIDUserLicenseServicePlan -ServicePlanName <String[]> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Filter
```
Get-PSEntraIDUserLicenseServicePlan -Filter <String> [-AdvancedFilter] [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get users who are assigned licenses with disabled and enabled service plans

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com
```

Get licenses of user username@contoso.com with service plans

## PARAMETERS

### -AdvancedFilter
Switch advanced filter for filtering accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Filter
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CompanyName
CompanyName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: ServicePlanNameCompanyName, ServicePlanIdCompanyName, SkuPartNumberCompanyName, SkuIdCompanyName, CompanyName
Aliases: Company

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EnableException
This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly,
but allows catching exceptions in calling scripts.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter expressions of accounts in tenant/directory.

```yaml
Type: System.String
Parameter Sets: Filter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: Identity
Aliases: Id, UserPrincipalName, Mail

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServicePlanId
Office 365 product GUID is identified using a GUID of ServicePlan.

```yaml
Type: System.String[]
Parameter Sets: ServicePlanIdCompanyName, ServicePlanId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServicePlanName
Friendly name Office 365 product of ServicePlanName.

```yaml
Type: System.String[]
Parameter Sets: ServicePlanNameCompanyName, ServicePlanName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkuId
Office 365 product GUID is identified using a GUID of SubscribedSku.

```yaml
Type: System.String[]
Parameter Sets: SkuIdCompanyName, SkuId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkuPartNumber
Friendly name Office 365 product of SubscribedSku.

```yaml
Type: System.String[]
Parameter Sets: SkuPartNumberCompanyName, SkuPartNumber
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSMicrosoftEntraID.User.License
## NOTES

## RELATED LINKS
