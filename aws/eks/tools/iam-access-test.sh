#!/bin/bash

# Define AWS CLI commands to test various services
check_ec2="aws ec2 describe-instances --max-items 1"
check_s3="aws s3 ls"
check_sns="aws sns list-topics"
check_sqs="aws sqs list-queues"
check_lambda="aws lambda list-functions --max-items 1"
check_dynamodb="aws dynamodb list-tables --max-items 1"
check_cloudformation="aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE"
check_rds="aws rds describe-db-instances --max-records 1"
check_route53="aws route53 list-hosted-zones --max-items 1"
check_iam="aws iam list-users --max-items 1"
check_kms="aws kms list-keys --limit 1"
check_logs="aws logs describe-log-groups --max-items 1"
check_apigateway="aws apigateway get-rest-apis --limit 1"
check_ecs="aws ecs list-clusters --max-items 1"
check_vpc="aws ec2 describe-vpcs --max-items 1"
check_efs="aws efs describe-file-systems --max-items 1"
check_glacier="aws glacier list-vaults --limit 1"
check_redshift="aws redshift describe-clusters --max-records 1"
check_cloudwatch="aws cloudwatch list-metrics --metric-name CPUUtilization --namespace AWS/EC2 --max-items 1"
check_elb="aws elbv2 describe-load-balancers --max-items 1"

# Array of commands to test access
commands=(
  "$check_ec2"
  "$check_s3"
  "$check_sns"
  "$check_sqs"
  "$check_lambda"
  "$check_dynamodb"
  "$check_cloudformation"
  "$check_rds"
  "$check_route53"
  "$check_iam"
  "$check_kms"
  "$check_logs"
  "$check_apigateway"
  "$check_ecs"
  "$check_vpc"
  "$check_efs"
  "$check_glacier"
  "$check_redshift"
  "$check_cloudwatch"
  "$check_elb"
)

# Loop through commands and execute them
for cmd in "${commands[@]}"; do
    echo "Executing: $cmd"
    if output=$($cmd 2>&1); then
        echo -e "\e[32mAccess Check: SUCCESS\e[0m"
    else
        echo "Access Check: FAILURE"
        echo "Error: $output"
    fi
    echo "--------------------------------"
done
