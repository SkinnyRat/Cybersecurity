# 22.4.2 — Analysing Data with BloodHound

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.4.2)
- Code blocks: 2

> BloodHound ingests the SharpHound zip into a **Neo4j** graph DB and finds attack paths (nodes =
> objects, edges = relationships). Output omitted.

## Start Neo4j (Kali)

```bash
sudo neo4j start
```

> Web UI at `http://localhost:7474`. Default creds **neo4j:neo4j** → you're forced to set a new
> password; remember it (BloodHound uses it to connect).

## Start BloodHound

```bash
bloodhound
```

## Workflow (GUI)

1. Log in to the Neo4j DB with your new password.
2. **Upload Data** (right side) → drag in the SharpHound `*_BloodHound.zip`.
3. Hamburger menu → **Database Info** to sanity-check counts (users, groups, sessions, ACLs).
4. **Analysis** tab → pre-built queries:
   - *Find all Domain Admins* — in the lab: `jeffadmin` + `administrator`.
   - *Find Shortest Paths to Domain Admins* — reveals paths manual enum missed (e.g. stephanie
     is **AdminTo** CLIENT74, where jeffadmin has a session).
   - Right-click an edge → **? Help** → **Abuse / Opsec / References** tabs explain how to exploit it.
5. **Mark objects as owned:** search the object → right-click → *Mark User/Computer as Owned*
   (skull icon). Mark everything you control (here: `stephanie` + `CLIENT75`).
6. *Find Shortest Paths to Domain Admins from Owned Principals* — now returns the concrete chain:
   CLIENT75 (stephanie session) → CLIENT74 (jeffadmin session) → Domain Admins.

> Manual enum first, then BloodHound to visualize — graph edges surface paths that are easy to
> miss by hand, though SharpHound's traffic is likely to be flagged.
