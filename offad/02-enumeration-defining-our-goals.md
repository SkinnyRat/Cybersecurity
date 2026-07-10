# 22.1.1 — Enumeration: Defining Our Goals

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.1.1)
- Code blocks: 0 _(scenario / methodology)_

## The scenario (assumed breach)

- Target domain: **corp.com** → `{{DOMAIN}}`.
- We already hold credentials for the low-privileged domain user **stephanie** → `{{USERNAME}}`
  (obtained via phishing, or handed to us for an **assumed-breach** assessment).
- `{{USERNAME}}` has **RDP** rights to a domain-joined Windows 11 host (CLIENT75) but is **not a
  local administrator** on it — a constraint that matters later.
- **Goal:** enumerate the full domain and find the path to the highest privilege possible
  (**Domain Admin**).

## The methodology that matters for the exam

- Enumerate from our current foothold first, then **pivot**: every time we gain a new account or
  host, **repeat the whole enumeration** from that new standpoint.
- Don't dismiss a "same-looking" low-priv account — admins grant individual users extra
  permissions based on their role, so a new account may unlock a new path.
- This persistent **"rinse and repeat"** loop is the key to AD enumeration, especially in large orgs.

> This scenario (stephanie → jeffadmin on CLIENT74 → Domain Admins) is the spine every command in
> the following sections is illustrating. See [[README]] for the full placeholder ↔ lab-value map.
