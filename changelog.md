# Changelog

## 1.0.0 (2025-07-22)
- **New:** Added advanced cmdlets for creating and updating Microsoft Entra ID (Azure AD) groups, including support for dynamic and security-enabled groups.
- **New:** Implemented batch request support for Microsoft Graph API, allowing efficient processing of multiple requests in a single call.
- **New:** Introduced `Get-PSEntraIDContact` cmdlet for retrieving organization contacts via Graph API.
- **New:** Added robust support for user creation and update, including all relevant properties (DisplayName, GivenName, Surname, Mail, JobTitle, Department, etc.).
- **New:** Extended parameter validation and error handling throughout the module for a more predictable scripting experience.
- **Upd:** Refactored core logic for property mapping in user and group cmdlets to align with Microsoft Graph API conventions.
- **Upd:** Enhanced pipeline support in user and group creation cmdlets, enabling bulk operations from CSV or other data sources.
- **Fix:** Addressed serialization and deserialization issues for batch responses, ensuring correct mapping of headers and body properties.
- **Fix:** Improved type handling and object mapping for Graph API responses, especially in edge cases with missing or null properties.