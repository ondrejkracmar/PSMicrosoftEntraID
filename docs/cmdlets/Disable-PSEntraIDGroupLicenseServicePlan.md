---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 04/21/2026
PlatyPS schema version: 2024-05-01
title: Disable-PSEntraIDGroupLicenseServicePlan
---

# Disable-PSEntraIDGroupLicenseServicePlan

## SYNOPSIS

Disables selected service plans within an assigned group license.

## DESCRIPTION

Calls `POST /groups/{id}/assignLicense` and recalculates the `disabledPlans` list for the specified group SKU so the selected service plans become disabled.
