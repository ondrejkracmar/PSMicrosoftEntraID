---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 04/21/2026
PlatyPS schema version: 2024-05-01
title: Disable-PSEntraIDGroupLicense
---

# Disable-PSEntraIDGroupLicense

## SYNOPSIS

Removes one or more licenses from a Microsoft Entra group.

## DESCRIPTION

Calls `POST /groups/{id}/assignLicense` with `removeLicenses` populated for the specified SKU identifiers.
