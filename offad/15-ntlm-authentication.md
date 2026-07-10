# 23.1.1 — NTLM Authentication

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.1.1)
- Code blocks: 0 _(conceptual — theory only)_

## When NTLM is used

- Client authenticates to a server **by IP address** (not hostname), or
- to a hostname **not registered** in AD-integrated DNS, or
- a third-party app explicitly chooses NTLM over Kerberos.

NTLM is an important fallback and used by many apps, so it's enabled in most environments.

## The 7-step challenge–response

1. Client computes the **NTLM hash** from the user's password.
2. Client sends the **username** to the server.
3. Server returns a random **nonce/challenge**.
4. Client encrypts the nonce with the NTLM hash → **response** → sends to server.
5. Server forwards **response + username + nonce** to the DC.
6. DC (which knows every user's NTLM hash) encrypts the nonce with the stored hash and compares.
7. If they match, authentication succeeds.

## Attacker relevance

- NTLM is a **fast hash** — Hashcat on good GPUs tests ~600 billion NTLM/s (8-char ≈ 2.5 h,
  9-char ≈ 11 days). Short passwords fall quickly.
- The hash can't be reversed, but it's **crackable** and **reusable** (Pass-the-Hash — see
  [[24-domain-controller-synchronization]] and the Lateral Movement module).
