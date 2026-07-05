# Section 8: Password Spraying Overview

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1424
- Code/command blocks: 1

> Terminal output is omitted; only commands & scripts are captured.

## When to spray (and when not to)

- **Spraying is domain-level, not per-machine.** You test creds against the DC (`crackmapexec smb {{DC_IP}} ...`), which authenticates the *whole domain*. Popping a new box does **not** mean re-spray — it's the same domain.
- **Do it once, early, only when you have usernames but no password** — or when new material appears.
- **Re-spray only on new material:** a fresh batch of valid usernames, or a new candidate password (cracked/looted) you want to test for reuse across accounts.
- **CHECK THE LOCKOUT POLICY FIRST** ([09](09-enumerating-retrieving-password-policies.md)). Get `lockoutThreshold` / `lockoutObservationWindow` *before* spraying — one guess per account per window. Spray blind and you lock accounts (and possibly fail the objective).
- **On every new box you do LOOT, not spray:** dump LSASS/SAM/`secretsdump`, grab creds from files/configs. That loot is what may surface new usernames/passwords → *then* consider another spray.
- **Got a hit? Stop spraying, pivot.** Move to credentialed enum ([14](14-credentialed-enumeration-from-linux.md)/[15](15-credentialed-enumeration-from-windows.md)), Kerberoasting, ACL abuse, lateral movement.

**Pipeline:** build user list ([10](10-password-spraying-making-a-target-user-list.md)) → check policy ([09](09-enumerating-retrieving-password-policies.md)) → spray from [Linux (11)](11-internal-password-spraying-from-linux.md) or [Windows (12)](12-internal-password-spraying-from-windows.md).

```bash
#!/bin/bash

for x in {{A..Z},{0..9}}{{A..Z},{0..9}}{{A..Z},{0..9}}{{A..Z},{0..9}}
    do echo $x;
done
```

