# Password Policy

## (deploy_fgpp.ps1)[deploy_fgpp.ps1]

This script allow to easilly define FGPP's and deploy it on your domain.
All FGPP settings are defined in (deploy_fgpp.xml)[deploy_fgpp.xml]

Polycy is defined by:
- Name
- Include default Built-In groups (Administrators, Account Operator, etc...) group and: `True/Flase`
- Include default Admin groups (Domain Admins, Schema Admins and Enterpise Admins): `True/Flase`

```xml
<policy name="AdminPasswordRule" BuiltinRoles="True" AdminRoles="True" Domain="">

</policy>
```

All policy setting are define by the following node:
```xml
<MinPasswordAge>1</MinPasswordAge>
<ComplexityEnabled>True</ComplexityEnabled>
<MinPasswordLength>15</MinPasswordLength>
<MaxPasswordAge>56</MaxPasswordAge>
<PasswordHistoryCount>13</PasswordHistoryCount>
<ReversibleEncryptionEnabled>False</ReversibleEncryptionEnabled>
<LockoutThreshold>5</LockoutThreshold>
<LockoutDuration>00:30</LockoutDuration>
<LockoutObservationWindow>00:30</LockoutObservationWindow>
<Precedence>100</Precedence>
```

You can include trageted groups or users using groups and users nodes:

```xml
<groups>
    <group>MyOtherAdminGroup</group>
</groups>
<users>
    <user>MyUser</user>
</users>
```