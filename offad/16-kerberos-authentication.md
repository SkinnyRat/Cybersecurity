# 23.1.2 — Kerberos Authentication

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.1.2)
- Code blocks: 0 _(conceptual — theory only)_

Microsoft's default auth protocol since Windows Server 2003 (based on MIT Kerberos v5). Unlike
NTLM's challenge-response with the app server, Kerberos is **ticket-based** and the client talks
to the **DC as the Key Distribution Center (KDC)** first, not the application server.

## The flow

1. **AS-REQ** — on login, client sends a timestamp encrypted with a hash derived from the user's
   password (Kerberos **preauthentication**).
2. **AS-REP** — DC looks up the user's hash in `ntds.dit`, decrypts the timestamp; if valid (and
   not a replay), replies with a **session key** + a **Ticket Granting Ticket (TGT)**. The TGT is
   encrypted with the **krbtgt** account's hash (known only to the KDC) so the client can't read
   it. TGT is valid ~10 hours.
3. **TGS-REQ** — to reach a resource, client sends the encrypted TGT + target SPN + a timestamp
   encrypted with the session key.
4. **TGS-REP** — KDC decrypts the TGT with the krbtgt key, validates (timestamp, username, client
   IP), and returns a **service ticket** encrypted with the **service account's** password hash.
5. **AP-REQ** — client sends the service ticket + username/timestamp to the application server,
   which decrypts it with its own account hash and grants access based on the group memberships
   embedded in the ticket.

## Why it matters (the attacks that follow)

- **AS-REP Roasting** — if preauth is disabled, request an AS-REP for any user and crack it offline. → [[19-as-rep-roasting]]
- **Kerberoasting** — request a service ticket for an SPN and crack the service account's hash. → [[20-kerberoasting]]
- **Silver Ticket** — forge a service ticket using the service account hash. → [[21-silver-tickets]]
- **Golden Ticket** — forge a TGT using the krbtgt hash (in the Lateral Movement module).
