import json
import boto3
import os

# Initialize EC2 client outside handler for better performance
ec2_client = None

def lambda_handler(event, context):
    """
    Lambda function to get EC2 public IP address
    
    Environment Variables needed:
    - EC2_INSTANCE_ID: The ID of your EC2 instance (e.g., i-001c671f7e3b9cf60)
    
    Note: AWS_REGION is automatically available in Lambda (reserved variable)
    """
    
    try:
        # Get instance ID from environment variable
        instance_id = os.environ.get('EC2_INSTANCE_ID')
        # AWS_REGION is automatically provided by Lambda environment
        region = os.environ.get('AWS_REGION', 'ap-south-1')
        
        print(f"Fetching IP for instance: {instance_id} in region: {region}")
        
        if not instance_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                },
                'body': json.dumps({
                    'error': 'EC2_INSTANCE_ID not configured'
                })
            }
        
        # Create EC2 client (reuse if already initialized)
        global ec2_client
        if ec2_client is None:
            ec2_client = boto3.client('ec2', region_name=region)
            print(f"Created new EC2 client for region: {region}")
        
        # Get instance details with timeout
        print(f"Calling describe_instances for {instance_id}...")
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        
        # Extract public IP
        reservations = response.get('Reservations', [])
        if not reservations or not reservations[0].get('Instances'):
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                },
                'body': json.dumps({
                    'error': 'Instance not found'
                })
            }
        
        instance = reservations[0]['Instances'][0]
        public_ip = instance.get('PublicIpAddress')
        instance_state = instance.get('State', {}).get('Name', 'unknown')
        
        if not public_ip:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                },
                'body': json.dumps({
                    'error': f'No public IP address found. Instance state: {instance_state}'
                })
            }
        
        # Return the public IP
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
            },
            'body': json.dumps({
                'ec2_public_ip': public_ip,
                'instance_id': instance_id,
                'instance_state': instance_state,
                'region': region
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
