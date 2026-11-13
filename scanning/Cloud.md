
## Pentesting cloud assets 

#### Approach A 

1. Enumerate as normal to find links to S3 or POST requests to other AWS resources. 
2. Base64 string with 2 dots = JWT ~ decode middle block for data, decrypt key with hashcat. 
3. Use key to sign new token, check if `is_admin`, `is_premium` etc; or LFI (with image URLs), RCE works. 
4. If AWS creds extracted (eg '/proc/self/environ'), try standard AWS methodology. 
5. Privesc vectors include `iam:ListUsers`, `iam:CreateAccessKey` ~ see AWS.md like #4. 

==== 

#### Approach B 

1. Enumerate as normal to find 'config.js', 'config.json' or similar, and fuzz resource URLs if needed. 
2. If source control like Gitea found, try looking around for emails and/or osint for login creds. 
3. Use `git secrets --register-aws` and `git secrets --scan-history` to scan for AWS creds. 
4. Try standard AWS methodology as usual; if 'tfstate' found = Terraform state ~ check for deployment & DB creds. 
5. If security groups found, try `aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,GroupId]' --output text` 
6. Try creating new security groups to open ports, spin up EC2 instances, connect to DBs etc. 

==== 

#### Approach C 

1. Enumerate as normal including dnsenum to find other IPs or URLs for a foothold. 
2. If internal POST forms found, try requests like http://169.254.169.254/latest/api/token , http://169.254.169.254/latest/meta-data/iam/security-credentials , http://169.254.169.254/latest/meta-data/iam/security-credentials/IntegrationRole 
3. Use `for cmd in list-{role,attached-role}-policies; do echo -e "\n=== $cmd ==="; aws iam $cmd --role-name IntegrationRole; done` to get attached role policies and look for 'AmazonSSMManagedInstanceCore', 'iam:PassRole' etc. 
4. For privesc, try creating a lamda with **AWSaudit.py** and using PassRole to grant full access. 

