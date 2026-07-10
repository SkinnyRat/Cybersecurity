# 24.3 — Wrapping Up (Lateral Movement in AD)

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.3)
- Code blocks: 0 _(summary)_

## What this module gave us

Using the hashes/tickets captured in Module 23, we moved between hosts and established persistence:

**Lateral movement (24.1)**
- **WMI / WinRM** — remote exec as a local-admin domain user ([[24-wmi-and-winrm]]).
- **PsExec** — interactive shell; needs local admin + ADMIN$ ([[25-psexec]]).
- **Pass the Hash** — auth with NTLM hash (NTLM only) ([[26-pass-the-hash]]).
- **Overpass the Hash** — NTLM hash → Kerberos TGT, then Kerberos tools ([[27-overpass-the-hash]]).
- **Pass the Ticket** — export + inject someone's TGS ([[28-pass-the-ticket]]).
- **DCOM** — MMC20.Application `ExecuteShellCommand` ([[29-dcom]]).

**Persistence (24.2)**
- **Golden Ticket** — forge TGTs from the krbtgt hash ([[30-golden-ticket]]).
- **Shadow Copies** — VSS-copy NTDS.dit + SYSTEM hive → dump all creds ([[31-shadow-copies]]).

## Exam-relevant reminders

- **NTLM vs Kerberos routing:** connecting by **IP → NTLM**, by **hostname → Kerberos**. Golden/
  overpass tickets only apply on the Kerberos path — always target the hostname.
- PtH works for domain accounts + built-in local Admin only (2014 update).
- Most techniques need **local admin on the target**; domain users skip the UAC remote restriction.
- This module completes the AD chain: **enumerate (Mod 22) → attack auth (Mod 23) → move/persist
  (Mod 24)**. Mirrors the htbad lateral-movement notes [[../htbad/README]].
