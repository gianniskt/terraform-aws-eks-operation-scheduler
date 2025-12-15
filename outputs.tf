output "lambda_function_arns" {
  description = "ARNs of the created Lambda functions"
  value       = { for k, v in aws_lambda_function.eks_scheduler : k => v.arn }
}

output "lambda_function_names" {
  description = "Names of the created Lambda functions"
  value       = { for k, v in aws_lambda_function.eks_scheduler : k => v.function_name }
}

output "eventbridge_rule_arns" {
  description = "ARNs of the EventBridge rules"
  value       = { for k, v in aws_cloudwatch_event_rule.eks_scheduler : k => v.arn }
}

output "eventbridge_rule_names" {
  description = "Names of the EventBridge rules"
  value       = { for k, v in aws_cloudwatch_event_rule.eks_scheduler : k => v.name }
}

output "iam_role_arns" {
  description = "ARNs of the IAM roles created for Lambda functions"
  value       = { for k, v in aws_iam_role.lambda_exec : k => v.arn }
}

output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.lambda_logs : k => v.name }
}

output "workflow_schedules" {
  description = "Map of workflow schedules for reference"
  value = {
    for k, v in local.workflows_map : k => {
      cluster_name    = v.cluster_name
      node_group_name = v.node_group_name
      action          = v.action
      cron_expression = v.cron_expression
      enabled         = v.enabled
    }
  }
}
