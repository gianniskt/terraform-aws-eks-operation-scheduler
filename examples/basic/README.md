# Basic Example - Single EKS Cluster Scheduling

This example demonstrates the simplest use case: scheduling a single EKS cluster to start and stop on weekdays.

## What This Does

- Creates Lambda functions to start/stop node group
- Creates EventBridge rules with weekly schedules
- Starts cluster at 8 AM UTC (Monday-Friday)
- Stops cluster at 6 PM UTC (Monday-Friday)

## Prerequisites

1. Existing EKS cluster named `my-eks-dev-cluster`
2. Existing node group named `my-node-group`
3. AWS credentials configured

## Usage

1. Update the cluster name and node group name in `main.tf`:

```hcl
cluster_name    = "your-actual-cluster-name"
node_group_name = "your-actual-node-group-name"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

3. Verify resources:

```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `eks-scheduler`)].FunctionName'

# List EventBridge rules
aws events list-rules --name-prefix eks-scheduler

# Check logs
aws logs tail /aws/lambda/eks-scheduler-dev-cluster-start --follow
```

## Testing Manually

Test the Lambda function without waiting for the schedule:

```bash
aws lambda invoke \
  --function-name eks-scheduler-dev-cluster-start \
  --log-type Tail \
  response.json

cat response.json
```

## Cost Estimate

- EKS Control Plane: $72/month (always running)
- Lambda: ~$0.20/month (20 invocations)
- EventBridge: Free tier
- EC2 Compute: ~$7/month (2x t3.medium, 8hrs/day, 5 days/week)
- **Total**: ~$79/month (vs $132 without scheduling)

## Cleanup

```bash
terraform destroy
```
