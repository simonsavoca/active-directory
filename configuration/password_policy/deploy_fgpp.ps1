<#
# Deploy FGPP
# Author: Simon sAVOCA

.EXAMPLE
    .\deploy_fgpp.ps1

.OUTPUTS
Logs the output in log in the current directory.

#>
[CmdletBinding()]
Param (
    [parameter(Mandatory=$False)]
        [string]$Mode = "Run"
)
$script:ErrorActionPreference = "SilentlyContinue"

Function getScriptDirectory {
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

Function debugLog {
    Param ([parameter(Mandatory=$true)]$debugInfo)
    "{0:G} {1:x}" -f  (get-date),$debugInfo >> $MyDebugFile
}

Function getDomainInformation {
    Try {
        Import-Module activeDirectory
        $script:RootDSE = ([ADSI]"LDAP://RootDSE")
        $script:ForestRootDomainDN = $RootDSE.rootDomainNamingContext
        $script:ForestRootDN = $RootDSE.RootDomain
        $script:CurrentForestObj = [system.directoryservices.activedirectory.forest]::GetCurrentForest()
        $script:rootDomainFQDN = $CurrentForestObj.RootDomain.Name
        $script:CurrentDomainDN = $RootDSE.Get("defaultNamingContext")
        $script:CurrentDomainObj = [system.directoryservices.activedirectory.domain]::GetCurrentDomain()
        $script:CurrentDomainFQDN = $CurrentDomainObj.name
        $script:CurrentDomainMode = $CurrentDomainObj.DomainMode
        $script:CurrentDomainSID = $(Get-ADDomain).domainSID.Value
    }
    Catch { Return $False }
    Return $True
}

Clear-Host
$startTime = Get-Date
$MyScriptName = "FGPP"
$MyDate = '{0:yyyyMMdd.HHmmss}' -f $startTime
$MyDebugFile = "$($MyScriptName)_$($MyDate).Log"
$MyPath = getScriptDirectory
Set-Location $MyPath

Write-Host "$MyScriptName started"
debuglog "$MyScriptName started"

If ($Mode -ne "Run") {
    Write-Host "`tTEST MODE ONLY, NO REAL ACTION" -ForegroundColor Yellow
    debuglog "    TEST MODE ONLY, NO REAL ACTION"
}

Write-Host "`tContacting Active Directory ..." -NoNewLine
If (!(getDomainInformation)) {
  Write-Host "Error" -ForegroundColor Red
  Write-Host "`tAD is unavailable" -ForegroundColor Red
  debuglog "    AD is unavailable. Exiting"
  $elapsed = (get-date) - $startTime
  Write-Host "Script completion Time: $elapsed"
  debuglog "Script completion Time: $elapsed"
  Exit 1
}
Else {
  Write-Host "Success" -ForegroundColor Green
  debuglog "    AD is available"
}

If ($Mode -eq "Run") {
  Write-Host "Checking domain mode ..." -NoNewLine
  $DomainMode = (Get-ADDomain).DomainMode
  # Domain Level check
  If (($DomainMode -ne "Windows2008R2Domain") -and ($DomainMode -ne "Windows2008Domain") -and ($DomainMode -ne "Windows2012R2Domain")) {
    debuglog "Domain mode: $DomainMode"
    debuglog "Domain mode prequisite is missing, Exiting."
    $elapsed = (get-date) - $startTime
    Write-Host "Script completion Time: $elapsed"
    debuglog "Script completion Time: $elapsed"
    Exit 1
  }
}

Write-Host "`tLoading configuration file ... " -NoNewLine
Try {
  [xml]$XMLData = Get-Content deploy_fgpp.xml -ErrorAction stop
  #[xml]$XMLData = Get-Content config_test.xml -ErrorAction stop
  Write-Host "Success" -ForegroundColor Green
  debuglog "    Configuration file loaded"
}
Catch {
  Write-Host "Error" -ForegroundColor Red
  debuglog "    $_.exception.message"
  debuglog "    Error importing configuration file. Exiting"
  $elapsed = (get-date) - $startTime
  Write-Host "Script completion Time: $elapsed"
  debuglog "Script completion Time: $elapsed"
  Exit 1
}

$Config = $XMLData.Config

Foreach ($PolicyDefinition in $Config.Policy) {

    $Found = $False
    Write-Host "`t----- $($PolicyDefinition.Name) -----"
    Write-Host "`tLoading $($PolicyDefinition.Name) policy definition ... " -NoNewLine
    $Policy = $PolicyDefinition.Name
    $FGPPBuiltinRoles = [System.Convert]::ToBoolean($($PolicyDefinition.BuiltinRoles))
    $FGPPAdminRoles = [System.Convert]::ToBoolean($($PolicyDefinition.AdminRoles))
    $FGPPForce = [System.Convert]::ToBoolean($($PolicyDefinition.Force))
    $FGPPCustomGroups = $PolicyDefinition.groups.group
    $FGPPCustomUsers = $PolicyDefinition.users.user
    $FGPPDomain = $PolicyDefinition.domain
    If (($FGPPDomain -ne "") -or ($FGPPDomain -ne $Null) -or ($FGPPDomain -eq $CurrentDomainFQDN)) {
        $FGPPParams = @{
            MinPasswordAge = $PolicyDefinition.MinPasswordAge
            ComplexityEnabled = [System.Convert]::ToBoolean($($PolicyDefinition.ComplexityEnabled))
            MinPasswordLength = $PolicyDefinition.MinPasswordLength
            MaxPasswordAge = $PolicyDefinition.MaxPasswordAge
            PasswordHistoryCount = $PolicyDefinition.PasswordHistoryCount
            ReversibleEncryptionEnabled = [System.Convert]::ToBoolean($($PolicyDefinition.ReversibleEncryptionEnabled))
            LockoutThreshold = $PolicyDefinition.LockoutThreshold
            LockoutDuration = $PolicyDefinition.LockoutDuration
            LockoutObservationWindow = $PolicyDefinition.LockoutObservationWindow
            Precedence = $PolicyDefinition.Precedence
        }
        Write-Host "Success" -ForegroundColor Green

        $FGPPList = Try { Get-ADFineGrainedPasswordPolicy -Filter * } Catch { $Null }

        Write-Host "`tVerifying name conflict ... " -NoNewLine
        If ($($FGPPList | Where-Object { $_.Name -eq $Policy })) {
        # Is existing FGPP with the same Name
            If ($FGPPForce) {
                Write-Host "Warning" -ForegroundColor Yellow
                Write-Host "`tUpdating $Policy ... " -NoNewLine
                Try {
                    Set-ADFineGrainedPasswordPolicy -Identity $Policy @FGPPParams
                    Write-Host "Success" -ForegroundColor Green
                }
                Catch {
                    Write-Host "Error" -ForegroundColor Red
                }
            }
            Else {
                Write-Host "Error" -ForegroundColor Red
                Write-Host "`tName conflict detected without force" -ForegroundColor Red
                Write-Host "`tSwitching to next policy"
                Continue
            }
        }

        Else {
          # No Create it
          Write-Host "Success" -ForegroundColor Green
          Write-Host "`tCreating $policy policy ... " -NoNewLine
          Try {
          If ($Mode -eq "Run") { New-ADFineGrainedPasswordPolicy -Name $Policy @FGPPParams }
          Write-Host "Success" -ForegroundColor Green
          }
          Catch {
          Write-Host "Error" -ForegroundColor Red
          Write-host $_.exception.message
          }
        }

        # To who the script applies to ?
        $FGPPDNList = @()
        $FGPPDNListError = @()

        Write-Host "`tBuilding subjects list ... " -NoNewLine
        # Builtins ?
        If ($FGPPBuiltinRoles) {
            $BuiltinAdminsSID = @("S-1-5-32-548",   # Account Operators
                                  "S-1-5-32-551",   # Backup Operators
                                  "S-1-5-32-556",   # Network Operators
                                  "S-1-5-32-549",   # Server Operators
                                  "S-1-5-32-544"    # Administrators
                                )
            Foreach ($SID in $BuiltinAdminsSID) {
                $GroupDN = Try { $(Get-ADObject -Filter { objectSID -eq $SID }).distinguishedName } Catch { $Null }
                If ($GroupDN) { $FGPPDNList += $GroupDN }
            }
        }
        # Admins ?
        If ($FGPPAdminRoles) {
            $DomainAdminsSID = @($($CurrentDomainSID + "-512"),  # Domain Admins
                                 $($CurrentDomainSID + "-519"),  # Enterprise Admins
                                 $($CurrentDomainSID + "-518")   # Schema Admins
                                )
            Foreach ($SID in $DomainAdminsSID)  {
                $GroupDN = Try { $(Get-ADObject -Filter { objectSID -eq $SID }).distinguishedName } Catch { $Null }
                If ($GroupDN) { $FGPPDNList += $GroupDN }
            }
        }
        # Custom groups ?
        If ($FGPPCustomGroups) {
            Foreach ($Group in $FGPPCustomGroups) {
                $GroupDN = Try { $(Get-ADObject -Filter { cn -eq $Group }).distinguishedName } Catch { $Null }
                If ($GroupDN) { $FGPPDNList += $GroupDN }
                Else { $FGPPDNListError += $Group }
            }
        }
        # Custom users ?
        If ($FGPPCustomUsers) {
            Foreach ($User in $FGPPCustomUsers) {
                $UserDN = Try { $(Get-ADObject -Filter { cn -eq $User }).distinguishedName } Catch { $Null }
                If ($UserDN) { $FGPPDNList += $UserDN }
                Else { $FGPPDNListError += $User }
            }
        }

        If (!$FGPPDNList -and !$FGPPDNListError) {
            Write-Host "Error" -ForegroundColor Red
            Write-Host "`t`tNo subject to proceed" -ForegroundColor Red
            Continue
        }
        ElseIf (!$FGPPDNList -and $FGPPDNListError) {
            Write-Host "Error" -ForegroundColor Red
            Write-Host "`t`tFollwing groups were not found: $FGPPDNListError" -ForegroundColor Yellow
            Write-Host "`t`tNo subject to proceed" -ForegroundColor Red
            Continue
        }
        ElseIf ($FGPPDNList -and $FGPPDNListError) {
            Write-Host "Warning" -ForegroundColor Yellow
            Write-Host "`t`tFollwing groups were not found: $FGPPDNListError" -ForegroundColor Yellow
        }
        Else {
            Write-Host "Success" -ForegroundColor Green
        }

        Foreach ($Subject in $FGPPDNList) {
            Write-Host "`tApplying $($PolicyDefinition.Name) to $Subject ... " -NoNewline
            If ($($FGPPList | Where-Object { $_.AppliesTo -Like $Subject })) {
                If ($FGPPForce) {
                    Write-Host "Warning" -ForegroundColor Yellow
                    Write-Host "`t`tSubject conflict with force mode" -ForegroundColor Yellow
                    # Apply FGPP
                    Write-Host "`tForcing policy ... " -NoNewLine
                    Try {
                        If ($Mode -eq "Run") { Add-ADFineGrainedPasswordPolicySubject -Identity $Policy -Subjects $Subject }
                        Write-Host "Success" -ForegroundColor Green
                    }
                    Catch {
                        Write-Host "Error" -ForegroundColor Red
                    }
                }
                Else {
                    Write-Host "Error" -ForegroundColor Red
                    Write-Host "`t`tSubject conflict without force mode" -ForegroundColor Red
                    Write-Host "`t`tConflict for $Subject" -ForegroundColor Red
                }
            }
            Else {
                Try {
                  If ($Mode -eq "Run") { Add-ADFineGrainedPasswordPolicySubject -Identity $Policy -Subjects $Subject }
                  Write-Host "Success" -ForegroundColor Green
                }
                Catch {
                  Write-Host "Error" -ForegroundColor Red
                }
            }
        }
    }
}
$elapsed = (get-date) - $startTime
Write-Host "Script completion Time: $elapsed"
debuglog "Script completion Time: $elapsed"
Exit 0
