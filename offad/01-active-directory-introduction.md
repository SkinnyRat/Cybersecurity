# 22.1 — Active Directory: Introduction

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.1)
- Code blocks: 0 _(conceptual — theory only)_

## Core concepts

- **Active Directory (AD DS)** is both a directory service and a management layer that stores
  **objects**: users, groups, and computers. Permissions on each object dictate its privileges.
- First thing an admin creates is a **domain name** (e.g. `corp.com`). AD has a hard dependency
  on **DNS** — a DC almost always also runs the authoritative DNS server for the domain.
- **Organizational Units (OUs)** are container "folders" that hold objects.
- Every object has **attributes** (a user has first name, last name, samAccountName, etc.).
- **Domain Controller (DC)** = the hub/core of the domain; stores all OUs, objects, and attributes.
  When a user logs in, the request goes to a DC to be validated. The DC is our primary focus.
- Objects can be grouped into **AD groups** so they're managed as a unit. Attackers target
  high-privilege groups.

## Privilege targets

- **Domain Admins** — complete control over the domain. Compromising a member ≈ owning the domain.
- **Enterprise Admins** — full control over **all** domains in the forest + Administrator on all
  DCs. One AD instance can host multiple domains in a **tree**, and multiple trees in a **forest**.

## Enumeration approach

Most manual AD enumeration relies on **LDAP** (the protocol used to talk to AD). We'll start with
built-in tools, then move to PowerShell/.NET LDAP queries, PowerView, and finally automate at
scale with SharpHound/BloodHound. Good enumeration directly improves success in the attack phase.
