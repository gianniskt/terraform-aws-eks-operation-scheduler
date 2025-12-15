# Multi-Cluster Example

This example demonstrates managing multiple EKS clusters with different scheduling requirements.

## Clusters in This Example

1. **dev-cluster**: Standard business hours (8 AM - 6 PM, Mon-Fri)
2. **staging-cluster**: Extended hours (7:30 AM - 8 PM, Mon-Fri)
3. **test-cluster**: Short hours (9 AM - 5 PM, Mon-Fri) in different region
4. **demo-cluster**: Part-time schedule (Mon/Wed/Fri only) - currently disabled

## Features Demonstrated

- Multiple clusters with different schedules
- Cross-region scheduling (us-east-1 and us-west-2)
- Different node group sizes per cluster
- Temporarily disabled schedules (demo-cluster)
- Different time windows for different environments

## Usage

1. Update cluster names and node group names in `main.tf`
2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Cost Estimate (4 Clusters)

| Cluster | Control Plane | Compute (scheduled) | Total/Month |
|---------|---------------|---------------------|-------------|
| dev     | $72           | $7                  | $79         |
| staging | $72           | $10                 | $82         |
| test    | $72           | $3                  | $75         |
| demo    | $72           | $0 (disabled)       | $72         |
| **Total** | **$288**    | **$20**             | **$308**    |

**Without scheduling**: ~$480/month  
**Savings**: ~$172/month (~36% reduction)

## Monitoring All Clusters

```bash
# List all scheduler Lambda functions
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `eks-scheduler`)].FunctionName'

# Tail logs for specific cluster
aws logs tail /aws/lambda/eks-scheduler-dev-cluster-start --follow

# Check all EventBridge rules
aws events list-rules --name-prefix eks-scheduler
```
