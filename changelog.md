# Changelog

## 1.1.0 (2025-10-06)
- **New:** Enhanced administrative unit management cmdlets with improved pipeline support and parameter optimization.
- **New:** Added centralized path variables for administrative unit API endpoints for better maintainability.
- **New:** Implemented $select parameter optimization for administrative unit cmdlets to improve API performance.
- **New:** Added comprehensive InputObject parameter support for Add-PSEntraIDAdministrativeUnitMember and Remove-PSEntraIDAdministrativeUnitMember cmdlets.
- **Upd:** Refactored Remove-PSEntraIDAdministrativeUnitMember parameter structure for cleaner parameter sets and better pipeline binding.
- **Upd:** Improved type safety in administrative unit member cmdlets with proper PSTypeName attributes and specific type declarations.
- **Upd:** Enhanced pipeline parameter binding for Remove-PSEntraIDAdministrativeUnit cmdlet using PSTypeName for better object acceptance.
- **Fix:** Resolved pipeline binding issues in administrative unit cmdlets that were causing "input object cannot be bound" errors.
- **Fix:** Corrected duplicate parameter set blocks and syntax errors in Remove-PSEntraIDAdministrativeUnitMember cmdlet.
- **Fix:** Streamlined parameter set logic to eliminate ambiguous pipeline binding scenarios.

## 1.0.2 (2025-09-18)
- **Fix:** Move License and README.MD file to root folder.

## 1.0.1 (2025-09-17)
- **Fix:** Incorrect verbosing of Get-PSEntraIDContact cmdlet.

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
