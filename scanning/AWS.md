## AWS enumeration & pentesting 


#### Get S3 buckets from public websites 

`aws --profile attacker iam put-user-policy --user-name enum --policy-name s3-read --policy-document file://policy-s3-read.json`
"StringLike": {"s3:ResourceAccount": ["1*"]}

Check that discovered user exists by trying to grant access to this user for an S3 bucket. 

> Use `pacu` to check if target account's IAM roles exist and if we can assume them.


#### Enumerating compromised profiles 

Check if target profile can run lambda functions: 

`aws --profile target lambda invoke --function-name arn:aws:lambda:us-east-1:123456789012:function:nonexistent-function outfile` 

Check attached IAM policies, and group inheritance: 

`aws --profile target iam list-attached-user-policies --user-name clouddesk-plove` 

`aws --profile target iam list-groups-for-user --user-name clouddesk-plove` 

`aws --profile target iam list-attached-group-policies --group-name support`

`aws --profile target iam get-policy-version --policy-arn arn:aws:iam::aws:policy/job-function/SupportUser --version-id v8` (check version id first) 

`aws --profile target iam list-users | tee  users.json` (also groups, roles) 


#### Using JMESPath to query json data 

`aws --profile target iam get-account-authorization-details --filter User --query "UserDetailList[].UserName"` 

`aws --profile target iam get-account-authorization-details --filter User --query "UserDetailList[0].{Name: UserName,Path: Path,Groups: GroupList}"` 
> The results might have custom fields worth investigating further. 

