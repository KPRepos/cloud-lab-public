# Make sure all required tools installed 
# apt update -y && apt install awscli less jq python3 python3-pip vim -y
# apt install python3-boto3 (or) pip3 install boto3
import boto3
import argparse

def check_access(service_name, check_function, successes):
    print(f"Executing: Check for {service_name}")
    try:
        check_function()
        successes.append(service_name)  # Add successful service name to the list
        print("\033[92mAccess Check: SUCCESS\033[0m")  # Green text for success
    except Exception as e:
        print("Access Check: FAILURE")
        print(f"Error: {e}")
    print("--------------------------------")

def main():
    parser = argparse.ArgumentParser(description="Check AWS service access.")
    parser.add_argument("--region", default="us-west-2", help="AWS region to use (default: us-west-2)")
    args = parser.parse_args()

    region = args.region
    session = boto3.Session(region_name=region)

    services = [
        ("EC2", lambda: session.client("ec2").describe_instances()),
        ("S3", lambda: session.client("s3").list_buckets()),
        ("SNS", lambda: session.client("sns").list_topics()),
        ("SQS", lambda: session.client("sqs").list_queues()),
        ("Lambda", lambda: session.client("lambda").list_functions()),
        ("DynamoDB", lambda: session.client("dynamodb").list_tables()),
        ("CloudFormation", lambda: session.client("cloudformation").list_stacks()),
        ("RDS", lambda: session.client("rds").describe_db_instances()),
        ("Route53", lambda: session.client("route53").list_hosted_zones()),
        ("IAM", lambda: session.client("iam").list_users()),
        ("KMS", lambda: session.client("kms").list_keys()),
        ("CloudWatch Logs", lambda: session.client("logs").describe_log_groups()),
        ("API Gateway", lambda: session.client("apigateway").get_rest_apis()),
        ("ECS", lambda: session.client("ecs").list_clusters()),
        ("VPC", lambda: session.client("ec2").describe_vpcs()),
        ("EFS", lambda: session.client("efs").describe_file_systems()),
        ("Glacier", lambda: session.client("glacier").list_vaults()),
        ("Redshift", lambda: session.client("redshift").describe_clusters()),
        ("CloudWatch", lambda: session.client("cloudwatch").list_metrics()),
        ("ELB", lambda: session.client("elbv2").describe_load_balancers()),
    ]

    successes = []  # List to store names of services that were successfully checked, defined within the 'main' scope

    for service_name, check_function in services:
        check_access(service_name, check_function, successes)

    # After all checks, print successes
    if successes:
        print("\033[92mAll successful access checks at the end:\033[0m")  # Green text
        for service in successes:
            print(f"- {service}")
    else:
        print("\033[91mNo successful access checks.\033[0m")  # Red text if no successes

if __name__ == "__main__":
    main()
