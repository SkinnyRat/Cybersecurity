# 22.3.3 — Enumeration Through Service Principal Names (SPNs)

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.3.3)
- Code blocks: 3

> A **Service Principal Name (SPN)** ties a service (MS SQL, IIS, Exchange…) to the **service
> account** running it. Enumerating SPNs reveals apps + their host/port straight from AD, with no
> port scan — and service accounts often have elevated privileges (future Kerberoast targets).
> Output omitted.

## Per-user SPNs with `setspn.exe` (built-in LOLBIN)

```cmd
setspn -L {{TARGET_USER}}
```

> e.g. `setspn -L iis_service` → `HTTP/web04.corp.com` (an IIS web server).

## All SPN accounts with PowerView

```powershell
Get-NetUser -SPN | select samaccountname,serviceprincipalname
```

> Lists every account with a registered SPN in one shot (e.g. `krbtgt`, `iis_service`).

## Resolve the service host

```powershell
nslookup.exe {{COMPUTER_NAME}}.{{DOMAIN}}
```

> Resolve the SPN's hostname to its internal IP, then browse/attack the service. Document each
> SPN account — they're prime targets in the upcoming *Attacking AD Authentication* module
> (Kerberoasting). See [[../htbad/17-kerberoasting-from-linux]] and
> [[../htbad/18-kerberoasting-from-windows]].
