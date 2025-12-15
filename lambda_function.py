import boto3
import os
import json
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to start/stop EKS node groups by scaling Auto Scaling Groups
    
    Environment Variables:
        CLUSTER_NAME: Name of the EKS cluster
        NODE_GROUP_NAME: Name of the node group
        REGION: AWS region
        ACTION: 'start' or 'stop'
        MIN_SIZE: Minimum size for start action
        DESIRED_SIZE: Desired capacity for start action
        MAX_SIZE: Maximum size for start action
    """
    
    cluster_name = os.environ['CLUSTER_NAME']
    node_group_name = os.environ['NODE_GROUP_NAME']
    region = os.environ['REGION']
    action = os.environ['ACTION']
    
    print(f"Starting {action} operation for cluster: {cluster_name}, node group: {node_group_name}")
    
    try:
        # Initialize AWS clients
        eks_client = boto3.client('eks', region_name=region)
        asg_client = boto3.client('autoscaling', region_name=region)
        
        # Get node group details to find the Auto Scaling Group
        response = eks_client.describe_nodegroup(
            clusterName=cluster_name,
            nodegroupName=node_group_name
        )
        
        node_group = response['nodegroup']
        asg_resources = node_group.get('resources', {}).get('autoScalingGroups', [])
        
        if not asg_resources:
            raise Exception(f"No Auto Scaling Group found for node group {node_group_name}")
        
        asg_name = asg_resources[0]['name']
        print(f"Found Auto Scaling Group: {asg_name}")
        
        # Get current ASG configuration
        asg_response = asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        
        if not asg_response['AutoScalingGroups']:
            raise Exception(f"Auto Scaling Group {asg_name} not found")
        
        current_asg = asg_response['AutoScalingGroups'][0]
        current_desired = current_asg['DesiredCapacity']
        current_min = current_asg['MinSize']
        current_max = current_asg['MaxSize']
        
        print(f"Current ASG state - Min: {current_min}, Desired: {current_desired}, Max: {current_max}")
        
        # Perform the action
        if action == 'stop':
            # Scale down to zero
            print("Scaling node group to zero...")
            asg_client.update_auto_scaling_group(
                AutoScalingGroupName=asg_name,
                MinSize=0,
                DesiredCapacity=0,
                MaxSize=0
            )
            print(f"Successfully scaled node group {node_group_name} to zero")
            
        elif action == 'start':
            # Scale up to desired capacity
            min_size = int(os.environ.get('MIN_SIZE', 1))
            desired_size = int(os.environ.get('DESIRED_SIZE', 2))
            max_size = int(os.environ.get('MAX_SIZE', 3))
            
            print(f"Scaling node group up - Min: {min_size}, Desired: {desired_size}, Max: {max_size}")
            
            asg_client.update_auto_scaling_group(
                AutoScalingGroupName=asg_name,
                MinSize=min_size,
                DesiredCapacity=desired_size,
                MaxSize=max_size
            )
            print(f"Successfully scaled node group {node_group_name} to desired capacity")
        
        else:
            raise ValueError(f"Invalid action: {action}. Must be 'start' or 'stop'")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully {action}ed node group {node_group_name}',
                'cluster': cluster_name,
                'nodeGroup': node_group_name,
                'action': action,
                'asgName': asg_name
            })
        }
        
    except ClientError as e:
        error_message = f"AWS API Error: {e.response['Error']['Message']}"
        print(error_message)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message,
                'cluster': cluster_name,
                'nodeGroup': node_group_name,
                'action': action
            })
        }
    
    except Exception as e:
        error_message = f"Error: {str(e)}"
        print(error_message)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message,
                'cluster': cluster_name,
                'nodeGroup': node_group_name,
                'action': action
            })
        }
