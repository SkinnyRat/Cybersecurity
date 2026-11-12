# Natas → Web Pentest Methodology

Rule of thumb: the **bug classes** in Natas transfer, but the **specific bypasses** mostly don't. Real engagements are won on coverage and noticing things, not puzzle tricks.

---

## Interview CTF approach

> Recon the cheap stuff first (source, robots.txt, headers, cookies, hidden files), then find where user input reaches something dangerous and work out what filter or language quirk stands between you and that sink. If the source is available, read it before fuzzing, because most of the puzzle is usually spotting the one assumption the developer got wrong.

- **Talk through the recon order out loud**: view source → common files → headers/cookies → parameters. Interviewers grade the process as much as the solve.
- **Name the bug class before you exploit it**, e.g. "this looks like a command injection with a character blacklist."
- **When a filter blocks you, ask what it misses**: alternate quoting, `$IFS`, wildcards, nested `....//`, arrays instead of strings, encoding.
- **Encoded or encrypted data gets reversed step by step**. Decode, then look for known plaintext you can use (XOR, ECB blocks).

---

## Transferable: add to methodology

| Natas | Habit | Real-world form |
|---|---|---|
| 0–3, 6 | Content discovery beyond the UI | JS bundles, source maps, `.git/`, `.env`, `.bak`, swagger/openapi docs, forgotten admin paths |
| 4, 5 | Never trust client-asserted identity | `X-Forwarded-For` / `Host` header trust, role flags in cookies, JWT claims, localStorage |
| 8, 11, 18, 19 | Decode every token and look for structure | Base64'd JSON, unsigned or weakly signed session data, sequential or predictable IDs (IDOR) |
| 9, 10, 17 | Assume blind and confirm out-of-band | Command injection in admin panels and appliances, confirmed via timing or Burp Collaborator |
| 12, 13 | File upload: test extension, MIME type, magic bytes, and where the file lands | Still very common, especially combined with path traversal or stored XSS |
| 14–16 | SQLi persists in the corners | `ORDER BY`, search/report features, legacy endpoints; boolean/time blind with sqlmap |
| 20 | Newline/delimiter injection into any storage or output format | CRLF header injection, log injection, CSV injection |
| 21 | Add parameters the UI never sends | Mass assignment (`role=admin`, `isAdmin=true`) |
| 22 | Read the response body of redirects | Execution-after-redirect |
| 23, 24 | Type confusion: send arrays/objects where strings are expected | NoSQL injection (`{"$ne": null}`), Node `qs` parsing, loose comparisons |
| 25 | Filters that strip once are bypassable | Path traversal with nested sequences and encoding variants |
| 26, 33 | Spot serialized blobs | PHP (phpggc), Java (ysoserial), .NET ViewState |

---

## Mostly CTF quirks: recognise, don't drill

- **Perl `open()` pipes, `ARGV` filehandle, DBI `quote()` list context (29–32):** only relevant on legacy CGI. Keep the meta-lesson to "learn the dangerous sinks of the target's language."
- **ECB block manipulation (28):** rare. Know that repeated ciphertext blocks point to ECB.
- **Log poisoning to RCE (25):** old-school LFI chain, rarely lands on modern stacks.
- **Column truncation (27):** mostly dead in strict-mode DBs. Unicode normalization collisions are the modern cousin.
- **Phar deserialization (33):** niche since PHP 8 removed the auto-unserialize.
- **Brute-forcing a 640-value session space (18):** contrived setup; the lesson about predictable tokens carries over.

---

## Gaps Natas doesn't cover

- **Access control across roles and tenants:** IDOR/BOLA, horizontal and vertical privilege escalation. The #1 real-world finding.
- **Business logic:** race conditions, workflow skipping, abusing price or quantity values.
- **SSRF:** especially against cloud metadata endpoints.
- **Auth flows:** OAuth/OIDC misconfigurations, password reset, MFA bypass.
- **Client-side bugs:** XSS, CSRF, CORS, postMessage.

Next step: PortSwigger Web Security Academy fills these gaps better than more CTF series.
