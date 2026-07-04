# Section 13: Enumerating Security Controls

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1459
- Code/command blocks: 6

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-MpComputerStatus
```

```powershell
Get-AppLockerPolicy -Effective | select -ExpandProperty RuleCollections
```

```powershell
$ExecutionContext.SessionState.LanguageMode
```

```powershell
Find-LAPSDelegatedGroups
```

```powershell
Find-AdmPwdExtendedRights
```

```powershell
Get-LAPSComputers
```

