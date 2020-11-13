# Active Directory

## Password Policy

### Users

| Setting | Value |
| ------ | ------ |
| Enforce password history | 13 Days |
| Maximum password age | 56 Days * |
| Minimum password age | 1 Day |
| Minimum password length | 8 |
| Password must meet complexity requirements | Enabled |
| Store passwords using reversible encryption | Disabled |
| Account Lockout Duration | 15 Minutes |
| Account Lockout Threshold | 5 |
| Account Lockout account reset | 15 Minutes |


> MTSB need 60 days or less but choose a multiple of 7 will ensure that user password expiration will occur during week days.
> To define password more than 14 characters, you must apply a FGPP for `Domain Users` group.

### High Privileges accounts

This policy must be deployed by Fine Grained Password Policy (FGPP) on all identified built-in high privileges groups:

| Group | SID |
| ------ | ------ |
| Administrators | S-1-5-32-544 |
| Account Operators | S-1-5-32-548 |
| Server Operators | S-1-5-32-549 |
| Backup Operators | S-1-5-32-551 |
| Network Operators | S-1-5-32-556 |
| Domain Admins | `<Domain SID>`-512 |
| Enterprise Admins | `<Domain SID>`-519 |
| Schema Admins | `<Domain SID>`-518 |


| Setting | Value |
| ------ | ------ |
| Enforce password history | 13 Days |
| Maximum password age | 56 Days |
| Minimum password age | 1 Day |
| Minimum password length | 15 |
| Password must meet complexity requirements | Enabled |
| Store passwords using reversible encryption | Disabled |
| Account Lockout Duration | 30 Minutes |
| Account Lockout Threshold | 5 |
| Account Lockout account reset | 30 Minutes |

### Service accounts

This policy must be deployed by FGPP and must target your identified service accounts group.

| Setting | Value |
| ------ | ------ |
| Enforce password history | 13 Days |
| Maximum password age | 365 Days |
| Minimum password age | 1 Day |
| Minimum password length | 15 |
| Password must meet complexity requirements | Enabled |
| Store passwords using reversible encryption | Disabled |
| Account Lockout Duration | 30 Minutes |
| Account Lockout Threshold | 5 |
| Account Lockout account reset | 30 Minutes |

### PassFilt

Microsoft PaffFilt is a specific DLL dedicated to apply new password criterias.

https://docs.microsoft.com/en-us/windows/win32/secmgmt/password-filters

According the [documentation](https://docs.microsoft.com/fr-fr/windows/win32/secmgmt/strong-password-enforcement-and-passfilt-dll?), 
you will be able to add the following filters:

- Passwords may not contain the user's samAccountName (Account Name) value or entire displayName (Full Name value). Both checks are not case sensitive.
- The samAccountName is checked in its entirety only to determine whether it is part of the password. If the samAccountName is less than three characters long, this check is skipped.
- The displayName is parsed for delimiters: commas, periods, dashes or hyphens, underscores, spaces, pound signs, and tabs. If any of these delimiters are found, the displayName is split and all parsed sections (tokens) are confirmed to not be included in the password. Tokens that are less than three characters are ignored, and substrings of the tokens are not checked. For example, the name "Erin M. Hagens" is split into three tokens: "Erin", "M", and "Hagens". Because the second token is only one character long, it is ignored. Therefore, this user could not have a password that included either "erin" or "hagens" as a substring anywhere in the password.
- Passwords must contain characters from three of the five following categories.

| Character categories | Examples |
| ------ | ------ |
| Uppercase letters of European languages (A through Z, with diacritic marks, Greek and Cyrillic characters) | A, B, C, Z |
| Lowercase letters of European languages (a through z, sharp-s, with diacritic marks, Greek and Cyrillic characters) | a, b, c, z |
| Base 10 digits (0 through 9) | 0, 1, 2, 9 |
| Non-alphanumeric characters (special characters) | $,!,%,^,(){}[];:<>? |
| Any Unicode character that is categorized as an alphabetic character but is not uppercase or lowercase. This includes Unicode characters from Asian languages. | |
