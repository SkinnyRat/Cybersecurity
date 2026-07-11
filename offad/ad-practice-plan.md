# OSCP AD Practice Plan — 8 Weekends (HTB + PG)

Curated Active Directory practice for the OSCP+ exam AD set, drawn from **HTB (VIP)** retired
machines and **OffSec Proving Grounds Practice**. Scope constraint: **no HTB Pro Labs, no
multi-forest** (out of OSCP scope). Companion to the module notes in this folder (`01…32`) —
this file is a *tracker*, not part of the numbered module sequence.

> **Access reality (2026):** After the Vulnlab→HTB merge, Vulnlab **single-host machines** need
> **VIP+** ($25/mo) and the multi-machine **Chains** need the **Pro Labs** sub ($49/mo, separate
> from VIP+). Current **VIP** covers the retired single boxes below; it does **not** cover Chains.

---

## Table 1 — Boxes for practising *individual* skills

| Skill / primitive | HTB (diff) | PG (diff) | Done |
|---|---|---|---|
| Kerberoasting | Active (Easy) | Nagoya (Hard) | ☐ |
| AS-REP Roasting | Forest, Sauna (Easy) | Heist (Easy) | ☐ |
| GPP / cPassword (SYSVOL) | Active (Easy) | — | ☐ |
| Password spraying / user enum | Sauna (Easy) | Access, Nagoya | ☐ |
| DCSync | Forest, Blackfield | Resourced | ☐ |
| RBCD | Support (Easy) | Resourced (Int) | ☐ |
| ADCS (ESC1/7/8) | Escape, Certified, Manager, Authority (Med) | Hutch | ☐ |
| ACL abuse (GenericAll/WriteDACL) | Cascade, Certified | Nagoya | ☐ |
| Kerberos w/o Mimikatz (impacket) | Scrambled (Med) | — | ☐ |
| SeBackup/SeRestore + NTDS | Blackfield | Vault, Hokkaido | ☐ |
| LAPS / stored-cred looting | Timelapse (Easy) | Kevin | ☐ |
| DnsAdmins / priv-group abuse | Resolute (Med) | — | ☐ |
| gMSA / readGMSApassword | Intelligence, Search (Med) | — | ☐ |
| LDAP anon-bind enum | Return (Easy) | Hutch, Nara | ☐ |

## Table 2 — Exam-difficulty AD boxes (TJnull OSCP-like)

Self-contained single-domain boxes representative of the exam.

| Platform | Box | Diff | Chain | Done |
|---|---|---|---|---|
| HTB | Active | Easy | GPP → Kerberoast → DA | ☐ |
| HTB | Forest | Easy | AS-REP → BloodHound → DCSync | ☐ |
| HTB | Sauna | Easy | Spray/AS-REP → autologon → DCSync | ☐ |
| HTB | Return | Easy | LDAP → Server Operators → SYSTEM | ☐ |
| HTB | Support | Easy | LDAP decrypt → RBCD → DC | ☐ |
| HTB | Timelapse | Easy | PFX cert → LAPS | ☐ |
| HTB | Cascade | Med | LDAP/registry loot → recycle-bin → DA | ☐ |
| HTB | Resolute | Med | Spray → DnsAdmins DLL → SYSTEM | ☐ |
| HTB | Monteverde | Med | Spray → Azure AD Connect → DA | ☐ |
| HTB | Intelligence | Med | gMSA → constrained deleg → DA | ☐ |
| HTB | Escape | Med | MSSQL → ADCS ESC1 | ☐ |
| HTB | Blackfield | Hard | AS-REP → Backup Operators → NTDS | ☐ |
| PG | Access | Int | AD-like foothold → domain privesc | ☐ |
| PG | Heist | Easy | AS-REP roast chain | ☐ |
| PG | Hutch | Int | LDAP anon → ADCS | ☐ |
| PG | Resourced | Int | NTDS + RBCD → DA | ☐ |
| PG | Vault | Hard | Responder → SeBackup/SeRestore | ☐ |
| PG | Nagoya | Hard | Spray → Kerberoast → GenericAll → DA | ☐ |
| PG | Hokkaido | Int | foothold → priv abuse | ☐ |
| PG | Kevin | Easy | stored creds → domain | ☐ |

## Table 3 — Multi-machine AD sets (separate DC, single-forest)

**None available on current VIP or PG** (both ship AD as single self-contained hosts). True
foothold→pivot→separate-DC reps live in gated/self-hosted content:

| Option | Access | Fits scope? | Note |
|---|---|---|---|
| **Zephyr** | HTB Pro Labs ($49/mo) | ✅ | Best single OSCP-AD-set analogue |
| **Vulnlab Chains** (Sendai, Reflection…) | HTB Pro Labs ($49/mo) | ✅ (pick single-forest ones) | 16 chains, varied topologies |
| **GOAD-Light** | Self-hosted, free | ✅ single forest, 2 hosts + DC | Only the pivot mechanics; static |
| Full GOAD | Self-hosted, free | ❌ multi-forest | Out of scope |
| Dante | HTB Pro Labs | ◑ mixed net+AD | Broader than pure AD |

---

## The 8-weekend schedule

~2 easy or 1 medium/hard box per weekend-day (8–12 hr weekends). Pull boxes forward if a
weekend runs light.

- [ ] **WE1 — Tooling + roasting foundations:** Active, Forest (HTB). *Get BloodHound / PowerView / impacket / evil-winrm fluent; GPP, Kerberoast, AS-REP, first DCSync.*
- [ ] **WE2 — Spray → foothold → DCSync:** Sauna, Return, Support (HTB). *Spraying, LDAP loot, RBCD, autologon creds.*
- [ ] **WE3 — ACLs / delegation / LAPS:** Cascade, Resolute, Timelapse (HTB). *ACL abuse, DnsAdmins, constrained delegation, LAPS/PFX.*
- [ ] **WE4 — ADCS deep-dive (high exam value):** Escape, Certified + (Manager or Authority) (HTB). *ESC1/7/8, Certipy, shadow creds.*
- [ ] **WE5 — PG style-shift + set up pivoting:** Resourced, Access (PG). *Less-guided PG methodology; install & drill **ligolo-ng / chisel** even on single-host.*
- [ ] **WE6 — Harder PG AD:** Nagoya, Vault, Heist/Hutch (PG). *GenericAll, SeBackup/SeRestore, Responder→hash, ADCS under friction.*
- [ ] **WE7 — ⭐ Multi-machine chain rehearsal:** Zephyr / a Vulnlab chain (1-mo Pro Labs) **or** GOAD-Light. *Foothold on member → tunnel → own separate DC; cred reuse across hosts, proxychains'd BloodHound/secretsdump.*
- [ ] **WE8 — Timed mock AD set + patch weak spots:** re-run the chain *timed*, or 3 single boxes back-to-back under a clock. *Simulate the 40-pt AD set in ~4 hrs; finalize AD methodology cheatsheet.*

### The one non-negotiable — Weekend 7 (pivoting gap)

Single boxes never teach **pivot-to-a-separate-DC + cross-host cred reuse**. That is the only
skill you'd otherwise meet cold on exam day. Close it once, deliberately.

**Recommended route (best ROI): one month of HTB Pro Labs ($49), timed for WE7–8.** Gets Zephyr
+ 16 Vulnlab chains + all Pro Labs — varied topologies, zero setup, professionally maintained.
Do WE1–6 on existing subs, buy the single month only when you reach WE7, then cancel.

**Fallback (break-glass) route: self-hosted GOAD-Light.** *Held in reserve* — only spin up if
Pro Labs networking turns out to be as miserable as THM/OffSec and the sub gets rage-cancelled.
This machine can run it comfortably (63 GB RAM, 690 GB free), but it's one static topology with
real setup friction (WSL2↔VirtualBox hypervisor conflict, flaky Ansible provisioning), so it's
the last resort, not the default.

---

*Sources: [TJnull NetSecFocus Trophy Room](https://docs.google.com/spreadsheets/d/1dwSMIAPIam0PuRBkCiDI88pU3yzrqqHkDtBngUHNCw8/), [0xdf OffSec exam lists](https://0xdf.gitlab.io/cheatsheets/offsec), [HTB Vulnlab integration](https://help.hackthebox.com/en/articles/11582861-vulnlab-x-hack-the-box), [HTB Labs pricing](https://help.hackthebox.com/en/articles/7257535-htb-labs-subscriptions).*
