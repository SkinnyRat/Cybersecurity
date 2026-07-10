# 22.4.1 — Collecting Data with SharpHound

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.4.1)
- Code blocks: 3

> **SharpHound** is BloodHound's C# collector. It runs the same Windows API / LDAP queries we did
> manually (`NetSessionEnum`, Remote Registry, LDAP) and packages results into a zip for
> BloodHound. Prefer the latest release over the copy in `C:\Tools`. **Noisy** — generates a lot
> of network traffic. Output omitted.

## Import (PowerShell version)

```powershell
powershell -ep bypass
Import-Module .\Sharphound.ps1
```

## Check options

```powershell
Get-Help Invoke-BloodHound
```

> Counter-intuitively, the SharpHound PS module is driven by the **`Invoke-BloodHound`** cmdlet.

## Collect all data

```powershell
Invoke-BloodHound -CollectionMethod All -OutputDirectory {{OUTPUT}} -OutputPrefix "corp audit"
```

> `-CollectionMethod All` gathers everything except local GPO groups; output is a timestamped
> `*_BloodHound.zip` you transfer to Kali. A `.bin` cache file is also written — it only speeds up
> re-runs and can be safely deleted. `-Loop` / `-LoopDuration` re-run collection over time to catch
> new sessions; `-ZipPassword` password-protects the output zip.
