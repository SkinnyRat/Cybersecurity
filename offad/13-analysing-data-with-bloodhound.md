# 22.4.2 — Analysing Data with BloodHound

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.4.2)
- Code blocks: 3

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

## Raw Cypher queries (when no pre-built query fits)

> The **Raw Query** box (bottom of the GUI) runs Cypher directly — use it for plain listings the
> pre-built queries don't cover. `MATCH` selects nodes, `RETURN` graphs them, `-[:REL]->` is an edge.

```
MATCH (m:Computer) RETURN m                              // all computers (click a node for OS/props)
MATCH (m:User) RETURN m                                  // all domain users
MATCH p = (c:Computer)-[:HasSession]->(m:User) RETURN p  // active sessions — who is logged on where
```

> Other high-value **pre-built** queries (Analysis tab) beyond the two above: *List all Kerberoastable
> Accounts*, *Find Workstations where Domain Users can RDP*, *Find Servers where Domain Users can RDP*,
> *Find Computers where Domain Users are Local Admin*. A Domain Admin with a session on a box you can
> reach = extract their hash ([[17-cached-ad-credentials]]) once you own that box.

> Manual enum first, then BloodHound to visualize — graph edges surface paths that are easy to
> miss by hand, though SharpHound's traffic is likely to be flagged.
