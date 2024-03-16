
update below line with role name within sample yaml

`serviceAccountName`

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



## Notes

/usr/local/bin/aws --version has to be >= AWS CLI – 2.15.0 for podidentity to work