
update below line with role arn within sample yaml

    `eks.amazonaws.com/role-arn: arn:aws:iam::<your-account-id>:role/RoleName`

Run below once deployed

`kubectl  exec -it -n nginx-apps-ns nginx-deployment-xxxxxxx  -- /bin/sh`

`apt update -y && apt install less -y`

# Apt install awscli may not pull latest version in all images
`
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
`

`aws ec2 describe-instances`



