# Authentication Overview

Welcome to the beginner's guide to Entra Authentication.
Here we will try to get you up to speed on what you need to know to start executing PowerShell against services protected by Microsoft Entra authentication, such as the Graph API.

## Getting started

Fundamentally, to connect to an API, you need to perform three steps:

+ Create an "Application"
+ Assign the permissions you want to use
+ Configure the Authentication process you want to use

## Assumptions

This guide assumes you want to use PowerShell to connect to an API via Entra Authentication.
The code examples use `Connect-PSMicrosoftEntraID` from this module.

The authentication layer is adapted from [EntraAuth](https://github.com/FriedrichWeinmann/EntraAuth) by Friedrich Weinmann, which is where this guide comes from as well. You do not need to install EntraAuth - the parts this module uses ship with it, and the connect cmdlet is named `Connect-PSMicrosoftEntraID` rather than `Connect-EntraService`.

The concepts and guidance also applies to other coding languages - whether you want to connect via PowerShell, Python, Java or C#, the different authentication options and the setup on the Entra side remain the same.
Obviously, the code examples will not translate as well.

If you are planning to build a web application or a desktop app for end users however, this guide is probably not ideal.

## Guide

> General Topics

+ [Creating an Application](creating-applications.md)
+ [Application vs. Delegate Authentication](application-vs-delegate.md)
+ [API Permissions and you](api-permissions.md)
+ [Cmdlet Permissions Reference](cmdlet-permissions.md)
+ [Managing an Application & Troubleshooting logins](managing-applications.md)

> Setting up Authentication

+ [Delegate: Using the Browser directly](authenticate-browser.md)
+ [Delegate: DeviceCode](authenticate-devicecode.md)
+ [Application: Certificate](authenticate-certificate.md)
+ [Application: Client Secret](authenticate-clientsecret.md)
