# OSCP AD Practice Checklist

Reps tracker, not a reading log. Only check a node off once you can execute it **from memory,
no notes, under time pressure**. This maps the [HTB AD module](README.md) sections onto the
shape of the OSCP AD set (foothold → enum → escalate → pivot to DC) and layers in the gaps that
a journey-map diagram can't fix.

## Status legend
- `[ ]` not yet reliable — still learning
- `[~]` shaky — done once or twice, still checking syntax/cheat sheet
- `[x]` cold, timed, no notes

## Gap: Initial Foothold (not covered by this module at all)

The HTB module starts *after* you already have a foothold on the internal network. The real
OSCP AD set starts by popping box 1 via a web app / exposed service — a different skillset.
Track reps here separately, fed by the 50 standalone boxes:

- [ ] Web app → shell (upload bypass, LFI/RFI, deserialization, SQLi → RCE)
- [ ] Public exploit research & adaptation (searchsploit, GitHub PoCs, patching broken PoCs)
- [ ] Manual service enum → custom exploitation (no automated frameworks per exam rules)
- [ ] Buffer overflow (if still relevant to your exam version)

## Phase 1 — External Recon & Domain Enum
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| External recon principles | [04](04-external-recon-and-enumeration-principles.md) | [ ] | 0 | |
| Initial domain enum (nltest, rpcclient, ldapsearch) | [05](05-initial-enumeration-of-the-domain.md) | [ ] | 0 | |

## Phase 2 — Network Poisoning
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| LLMNR/NBT-NS poisoning — Linux (Responder) | [06](06-llmnr-nbtns-poisoning-from-linux.md) | [ ] | 0 | |
| LLMNR/NBT-NS poisoning — Windows (Inveigh) | [07](07-llmnr-nbtns-poisoning-from-windows.md) | [ ] | 0 | |

## Phase 3 — Password Attacks
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| Password spraying overview / OpSec | [08](08-password-spraying-overview.md) | [ ] | 0 | |
| Password policy enum | [09](09-enumerating-retrieving-password-policies.md) | [ ] | 0 | |
| Building a target user list | [10](10-password-spraying-making-a-target-user-list.md) | [ ] | 0 | |
| Internal spraying — Linux (kerbrute/nxc) | [11](11-internal-password-spraying-from-linux.md) | [ ] | 0 | |
| Internal spraying — Windows | [12](12-internal-password-spraying-from-windows.md) | [ ] | 0 | |

## Phase 4 — Credentialed Enumeration
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| Enumerating security controls (AV/AppLocker/LAPS/etc.) | [13](13-enumerating-security-controls.md) | [ ] | 0 | |
| Credentialed enum — Linux (BloodHound, nxc, ldapdomaindump) | [14](14-credentialed-enumeration-from-linux.md) | [ ] | 0 | |
| Credentialed enum — Windows (PowerView, ActiveDirectory module) | [15](15-credentialed-enumeration-from-windows.md) | [ ] | 0 | |
| Living off the land (native Windows tools) | [16](16-living-off-the-land.md) | [ ] | 0 | |

## Phase 5 — Kerberoasting / AS-REP
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| Kerberoasting — Linux (impacket) | [17](17-kerberoasting-from-linux.md) | [ ] | 0 | |
| Kerberoasting — Windows (Rubeus) | [18](18-kerberoasting-from-windows.md) | [ ] | 0 | |

## Phase 6 — ACL Abuse
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| ACL enumeration (BloodHound + manual) | [20](20-acl-enumeration.md) | [ ] | 0 | |
| ACL abuse tactics (GenericAll, WriteDACL, ForceChangePassword, etc.) | [21](21-acl-abuse-tactics.md) | [ ] | 0 | |

## Phase 7 — Domain Dominance
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| DCSync | [22](22-dcsync.md) | [ ] | 0 | |
| Privileged access abuse (PtH/PtT/overpass-the-hash) | [23](23-privileged-access.md) | [ ] | 0 | |
| Kerberos double-hop problem | [24](24-kerberos-double-hop-problem.md) | [ ] | 0 | |

## Phase 8 — Bleeding Edge & Misconfigs
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| Bleeding edge vulns (PetitPotam, PrintNightmare, ZeroLogon, etc.) | [25](25-bleeding-edge-vulnerabilities.md) | [ ] | 0 | check which still apply to exam-patched boxes |
| Misc misconfigurations | [26](26-miscellaneous-misconfigurations.md) | [ ] | 0 | |

## Phase 9 — Domain Trusts (lower priority for OSCP, but 1 rep worth doing)
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| Domain trusts primer | [27](27-domain-trusts-primer.md) | [ ] | 0 | |
| Child→parent — Windows | [28](28-attacking-domain-trusts-child-parent-from-windows.md) | [ ] | 0 | |
| Child→parent — Linux | [29](29-attacking-domain-trusts-child-parent-from-linux.md) | [ ] | 0 | |
| Cross-forest — Windows | [30](30-attacking-domain-trusts-cross-forest-from-windows.md) | [ ] | 0 | |
| Cross-forest — Linux | [31](31-attacking-domain-trusts-cross-forest-from-linux.md) | [ ] | 0 | |

## Phase 10 — Skills Assessments (the real reps)
| Node | Source | Status | Reps | Notes |
|---|---|---|---|---|
| Skills Assessment Part I — untimed | [34](34-skills-assessment-part-i.md) | [ ] | 0 | do open-book first |
| Skills Assessment Part I — timed, no notes | 34 | [ ] | 0 | |
| Skills Assessment Part II — untimed | [35](35-skills-assessment-part-ii.md) | [ ] | 0 | |
| Skills Assessment Part II — timed, no notes | 35 | [ ] | 0 | |

## Tool rules to drill in (not skills, but exam-day landmines)
- [ ] Metasploit/msfconsole — one target only, no automated AD modules chained across hosts
- [ ] No fully-automated exploitation frameworks (e.g. autopwn-style tools) for privesc chains
- [ ] Comfortable falling back to manual technique when the "easy" tool is off-limits

## Full-chain drills (foothold → DC, one sitting, timed)
Do these after individual nodes are `[x]`. This is what actually predicts exam performance —
chaining under pressure, not node-by-node recall.

| Target set | Status | Time taken | Notes |
|---|---|---|---|
| HTB: Active | [ ] | | |
| HTB: Forest | [ ] | | |
| HTB: Sauna | [ ] | | |
| HTB: Blackfield | [ ] | | |
| HTB: Escape | [ ] | | |
| PG Practice AD set #1 | [ ] | | |
| PG Practice AD set #2 | [ ] | | |

## How this ties to the [3-month plan](../README.md#plan-next-3-months)
- **Weekend 1–3 (lab redo):** work this checklist top to bottom against PEN-200 → THM → HTB AD
  labs respectively. Goal by end of weekend 3: every Phase 1–7 node at `[x]`.
- **Weekend 4:** PJPT exam.
- **Weekend 5–11:** one full-chain drill per weekend from the table above, timed, notes-as-you-go
  in exam format. Track time-to-DC-compromise trend across the 6-7 sets.
