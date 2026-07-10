# 24.1.3 — Pass the Hash (PtH)

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.1.3)
- Code blocks: 1

> Authenticate with a user's **NTLM hash** instead of the plaintext password. **NTLM only** — not
> Kerberos. Output omitted.

## Requirements

- SMB reachable (**TCP 445**) through the firewall.
- **File and Printer Sharing** enabled.
- **ADMIN$** share present → requires **local admin** rights for code execution.

## Pass the hash with Impacket (Kali)

```bash
/usr/bin/impacket-wmiexec -hashes :{{NTLM_HASH}} Administrator@{{TARGET_IP}}
```

> `-hashes :<NThash>` (empty LM half). Other Impacket/PtH tools: `impacket-psexec`,
> `impacket-smbexec`, `crackmapexec ... -H <hash>`. Works for **domain accounts** and the
> **built-in local Administrator**; a 2014 security update blocks other local admin accounts.
> If the target is only reachable via the first host, pivot/proxy through it. Hashes come from
> [[17-cached-ad-credentials]] / [[22-domain-controller-synchronization]].
