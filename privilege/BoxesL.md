
#### SOP for Linux 

0. Disk group: id => debugfs /dev/sdaX 
1. Check sudo -l 
2. SUID => GTFObins (eg strace, env) 
3. Cron jobs in /etc/crontab ; PATH has /dev/shm ? 
4. Find creds in /var/www 
5. Exploits, eg Polkit CVE-2021-4034 
