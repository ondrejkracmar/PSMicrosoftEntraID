---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 04/21/2026
PlatyPS schema version: 2024-05-01
title: Enable-PSEntraIDGroupLicense
---

# Enable-PSEntraIDGroupLicense

## SYNOPSIS

Assigns one or more licenses to a Microsoft Entra group.

## SYNTAX

### InputObjectSkuPartNumber (Default)

```powershell
Enable-PSEntraIDGroupLicense -InputObject <Group[]> -SkuPartNumber <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObjectSkuId

```powershell
Enable-PSEntraIDGroupLicense -InputObject <Group[]> -SkuId <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuPartNumber

```powershell
Enable-PSEntraIDGroupLicense -Identity <string[]> -SkuPartNumber <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuId

```powershell
Enable-PSEntraIDGroupLicense -Identity <string[]> -SkuId <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Calls `POST /groups/{id}/assignLicense` and adds the specified subscribed SKU identifiers to the group.
