
#### SOP for Windows 

0. Run whoami /all 
1. Look around for creds, log files, (and _run_) .ps1 
2. PowerShell history (C:\Users\user\appdata\roaming\microsoft\windows\powershell\psreadline) 
3. Potato or PrintSpoofer (run FullPowers.exe if missing privileges, or msfvenom rev shell) 
4. Services (eg `ps` or `sc.exe start|stop dns`) 
5. Run PowerUp or PrivescCheck (eg replace target exe with cmd, `icaclls`, `shutdown /r /t 0`) 


#### Unusual exploits 
Xampp => https://www.exploit-db.com/exploits/50337 
