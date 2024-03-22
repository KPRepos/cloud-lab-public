import boto3
import time


def lambda_handler(event, context):
    # Extract instance ID from the event
    instance_id = event['detail']['instance-id']
    state = event['detail']['state']

    # Initialize EC2 client
    ec2 = boto3.resource('ec2')

    # Get the instance object
    instance = ec2.Instance(instance_id)
    instance_name = ''

    # Check tags to find the name
    for tag in instance.tags:
        if tag['Key'] == 'Name':
            instance_name = tag['Value']
            break
    print(instance_name)
    print("checking state...")

    # Initialize Auto Scaling client
    autoscaling = boto3.client('autoscaling')

    # Specify your Auto Scaling Group name
    asg_name = "k8-worker-asg"

    # Check if the instance name is 'k8-ct1' and the state changed from 'running'
    if instance_name == 'k8-ct1' and state != 'running':
        max_retries = 10  # Set the maximum number of retries
        delay = 15  # 10 seconds delay between retries

        print(instance_name)
        for attempt in range(max_retries):
            try:
                # Attempt to initiate an instance refresh
                response = autoscaling.start_instance_refresh(
                    AutoScalingGroupName=asg_name
                )
                print(
                    f"Instance refresh started for ASG: {asg_name}, Response: {response}")
                break  # Exit the loop on success
            except autoscaling.exceptions.InstanceRefreshInProgressFault:
                print(
                    f"Attempt {attempt + 1}: Instance Refresh in progress. Retrying in {delay} seconds...")
                # Wait for the specified delay before retrying
                time.sleep(delay)
            except Exception as e:
                print(f"An unexpected error occurred: {e}")
                break  # Exit the loop if an unexpected error occurs
    else:
        print(
            f"No action taken for instance {instance_id} with name {instance_name}.")

    return {
        'statusCode': 200,
        'body': 'Lambda function executed successfully!'
    }
