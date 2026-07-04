# Active Directory Enumeration & Attacks — Commands & Scripts

Commands and scripts collected from every section of the Hack The Box Academy module
**[Active Directory Enumeration & Attacks](https://academy.hackthebox.com/module/details/143)** (module 143, 36 sections).

## Attack journey map

A visual overview of how the sections connect — from foothold to forest compromise:

![AD attack journey map](ad-attack-journey-map.png)

Reading the map ≠ executing the chain from memory under a clock. Track actual reps against it
in the **[OSCP practice checklist](oscp-practice-checklist.md)**.

## How this was collected

Each section page was read and its code blocks extracted. To keep the files focused on
what's actionable:

- **Commands** from terminal sessions (`shellsession`, `cmd`, `powershell` prompts) are kept; the
  surrounding terminal **output is omitted** (marked `_(output omitted)_`).
- **Scripts / code snippets** (PowerShell, Python, Cypher, etc.) are kept in full.
- Very long single-line arguments (e.g. raw SDDL strings, base64 blobs) are truncated with a
  `<SNIP ...>` marker.
- Each file lists its source section URL so you can jump back to the full lesson.

## Sections

| # | Section | File |
|---|---------|------|
| 1 | Introduction to AD Enumeration & Attacks | [01](01-introduction-to-ad-enumeration-attacks.md) |
| 2 | Tools of the Trade | [02](02-tools-of-the-trade.md) |
| 3 | Scenario | [03](03-scenario.md) |
| 4 | External Recon and Enumeration Principles | [04](04-external-recon-and-enumeration-principles.md) |
| 5 | Initial Enumeration of the Domain | [05](05-initial-enumeration-of-the-domain.md) |
| 6 | LLMNR/NBT-NS Poisoning - from Linux | [06](06-llmnr-nbtns-poisoning-from-linux.md) |
| 7 | LLMNR/NBT-NS Poisoning - from Windows | [07](07-llmnr-nbtns-poisoning-from-windows.md) |
| 8 | Password Spraying Overview | [08](08-password-spraying-overview.md) |
| 9 | Enumerating & Retrieving Password Policies | [09](09-enumerating-retrieving-password-policies.md) |
| 10 | Password Spraying - Making a Target User List | [10](10-password-spraying-making-a-target-user-list.md) |
| 11 | Internal Password Spraying - from Linux | [11](11-internal-password-spraying-from-linux.md) |
| 12 | Internal Password Spraying - from Windows | [12](12-internal-password-spraying-from-windows.md) |
| 13 | Enumerating Security Controls | [13](13-enumerating-security-controls.md) |
| 14 | Credentialed Enumeration - from Linux | [14](14-credentialed-enumeration-from-linux.md) |
| 15 | Credentialed Enumeration - from Windows | [15](15-credentialed-enumeration-from-windows.md) |
| 16 | Living Off the Land | [16](16-living-off-the-land.md) |
| 17 | Kerberoasting - from Linux | [17](17-kerberoasting-from-linux.md) |
| 18 | Kerberoasting - from Windows | [18](18-kerberoasting-from-windows.md) |
| 19 | Access Control List (ACL) Abuse Primer | [19](19-access-control-list-acl-abuse-primer.md) |
| 20 | ACL Enumeration | [20](20-acl-enumeration.md) |
| 21 | ACL Abuse Tactics | [21](21-acl-abuse-tactics.md) |
| 22 | DCSync | [22](22-dcsync.md) |
| 23 | Privileged Access | [23](23-privileged-access.md) |
| 24 | Kerberos "Double Hop" Problem | [24](24-kerberos-double-hop-problem.md) |
| 25 | Bleeding Edge Vulnerabilities | [25](25-bleeding-edge-vulnerabilities.md) |
| 26 | Miscellaneous Misconfigurations | [26](26-miscellaneous-misconfigurations.md) |
| 27 | Domain Trusts Primer | [27](27-domain-trusts-primer.md) |
| 28 | Attacking Domain Trusts - Child → Parent - from Windows | [28](28-attacking-domain-trusts-child-parent-from-windows.md) |
| 29 | Attacking Domain Trusts - Child → Parent - from Linux | [29](29-attacking-domain-trusts-child-parent-from-linux.md) |
| 30 | Attacking Domain Trusts - Cross-Forest - from Windows | [30](30-attacking-domain-trusts-cross-forest-from-windows.md) |
| 31 | Attacking Domain Trusts - Cross-Forest - from Linux | [31](31-attacking-domain-trusts-cross-forest-from-linux.md) |
| 32 | Hardening Active Directory | [32](32-hardening-active-directory.md) |
| 33 | Additional AD Auditing Techniques | [33](33-additional-ad-auditing-techniques.md) |
| 34 | Skills Assessment Part I | [34](34-skills-assessment-part-i.md) |
| 35 | Skills Assessment Part II | [35](35-skills-assessment-part-ii.md) |
| 36 | Beyond this Module | [36](36-beyond-this-module.md) |

_Sections 2, 3, 19, 34, 35 and 36 contain no command/script blocks (overview, scenario, or lab-only pages)._
