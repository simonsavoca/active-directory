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


* MTSB need 60 days or less but choose a multiple of 7 will ensure that user password expiration will occur during week days.

### High Privileges accounts

This policy must be deployed by Fine Grained Password Policy (FGPP) on all identified built-in high privileges groups:

| Group | SID |
| ------ | ------ |
| Administrators | S-1-5-32-544 |
| AccountOperators | S-1-5-32-548 |
| ServerOperators | S-1-5-32-549 |
| BackupOperators | S-1-5-32-551 |
| NetworkOperators | S-1-5-32-556 |
| DomainAdmins | <Domain SID>-512 |
| EnterpriseAdmins | <Domain SID>-519 |
| SchemaAdmins | <Domain SID>-518 |


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

