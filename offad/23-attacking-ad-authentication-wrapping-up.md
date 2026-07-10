# 23.3 — Wrapping Up (Attacking AD Authentication)

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.3)
- Code blocks: 0 _(summary)_

## What this module gave us

Using the enumeration output from Module 22, we attacked AD's two auth protocols to obtain
credentials and access:

- **Theory** — NTLM challenge-response ([[15-ntlm-authentication]]) and Kerberos ticketing
  ([[16-kerberos-authentication]]); where creds/tickets are cached in **LSASS**
  ([[17-cached-ad-credentials]]).
- **Password attacks** — spray via LDAP/`Spray-Passwords`, `crackmapexec` (SMB, flags `Pwn3d!`),
  `kerbrute` (quiet AS-REQ) — mind lockout ([[18-password-attacks]]).
- **AS-REP Roasting** — no-preauth users, crack offline (mode 18200) ([[19-as-rep-roasting]]).
- **Kerberoasting** — crack SPN service-account TGS (mode 13100) ([[20-kerberoasting]]).
- **Silver Tickets** — forge a service ticket from the SPN hash ([[21-silver-tickets]]).
- **DCSync** — impersonate a DC to pull any hash, incl. `krbtgt`/`Administrator`
  ([[22-domain-controller-synchronization]]).

## Exam-relevant reminders

- Most attacks have **both Windows (Rubeus/Mimikatz) and Linux (Impacket) paths** — know both.
- Hashcat modes to memorize: **NTLM 1000**, **AS-REP 18200**, **TGS-REP 13100**.
- Clean up artifacts (targeted-roast SPNs/UAC flips). Lockout awareness before any spray.

## Next

The credentials/hashes obtained here get used to **move laterally** in the next module (PtH, PtT,
Overpass-the-Hash, PsExec, WMI/WinRM, DCOM, Golden Ticket) — files `24`+ in this set, mirroring
the htbad lateral-movement notes [[../htbad/README]].
