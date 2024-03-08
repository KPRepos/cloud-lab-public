
update below line with tole arn within sample yaml

    `eks.amazonaws.com/role-arn: arn:aws:iam::<your-account-id>:role/RoleName`

Run below once deployed

`kubectl  exec -it -n nginx-apps-ns nginx-deployment-xxxxxxx  -- /bin/sh`

`apt update -y`
`apt install awscli` 
`apt install less`

`aws ec2 describe-instances`

