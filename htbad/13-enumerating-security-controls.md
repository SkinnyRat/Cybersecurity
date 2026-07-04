# Section 13: Enumerating Security Controls

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1459
- Code/command blocks: 6

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Get-MpComputerStatus
```

## 2. `powershell` _(output omitted)_

```powershell
Get-AppLockerPolicy -Effective | select -ExpandProperty RuleCollections
```

## 3. `powershell` _(output omitted)_

```powershell
$ExecutionContext.SessionState.LanguageMode
```

## 4. `powershell` _(output omitted)_

```powershell
Find-LAPSDelegatedGroups
```

## 5. `powershell` _(output omitted)_

```powershell
Find-AdmPwdExtendedRights
```

## 6. `powershell` _(output omitted)_

```powershell
Get-LAPSComputers
```

