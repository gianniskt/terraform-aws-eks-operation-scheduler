# Monthly Scheduling Example

This example demonstrates monthly scheduling patterns for EKS clusters.

## Monthly Schedule Types

### 1st Monday of Each Month
```hcl
start_schedule = {
  type   = "monthly"
  week   = 1          # 1st occurrence
  day    = "Monday"
  hour   = 8
  minute = 0
}
```
**EventBridge Cron**: `cron(0 8 ? * MON#1 *)`

### 2nd Wednesday of Each Month
```hcl
start_schedule = {
  type   = "monthly"
  week   = 2          # 2nd occurrence
  day    = "Wednesday"
  hour   = 9
  minute = 0
}
```
**EventBridge Cron**: `cron(0 9 ? * WED#2 *)`

## Use Cases

- **Monthly maintenance windows**: Run cluster only on patch Tuesday
- **Monthly reporting**: Start cluster for end-of-month processing
- **Bi-weekly demos**: Run cluster every 2nd and 4th Friday
- **Quarterly reviews**: Combine with enabled/disabled flags

## EventBridge Cron Format

```
cron(minute hour day-of-month month day-of-week#occurrence year)

Examples:
- 1st Monday:     cron(0 8 ? * MON#1 *)
- 2nd Tuesday:    cron(0 9 ? * TUE#2 *)
- 3rd Friday:     cron(0 10 ? * FRI#3 *)
- 4th Thursday:   cron(0 11 ? * THU#4 *)
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Testing

Verify the schedule was created correctly:

```bash
# Check EventBridge rule schedule
aws events describe-rule --name eks-scheduler-monthly-cluster-1-start

# View the cron expression
aws events describe-rule --name eks-scheduler-monthly-cluster-1-start \
  --query 'ScheduleExpression'
```

## Cost Estimate

Monthly scheduling is ideal for minimal usage:
- Control Plane: $72/month (always)
- Compute: ~$1-2/month (1-2 days of usage)
- Lambda: ~$0.10/month (2-4 invocations)
- **Total**: ~$73-74/month (vs $132 without scheduling)
