# Package Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  for_each = local.workflows_map

  name = "eks-scheduler-${each.value.cluster_key}-${each.value.action}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name        = "eks-scheduler-${each.value.cluster_key}-${each.value.action}"
    Cluster     = each.value.cluster_name
    NodeGroup   = each.value.node_group_name
    Action      = each.value.action
    ManagedBy   = "terraform"
  })
}

# IAM Policy for Lambda to manage EKS node groups
resource "aws_iam_role_policy" "lambda_eks_policy" {
  for_each = local.workflows_map

  name = "eks-scheduler-policy"
  role = aws_iam_role.lambda_exec[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "arn:aws:eks:${each.value.region}:*:cluster/${each.value.cluster_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeNodegroup"
        ]
        Resource = "arn:aws:eks:${each.value.region}:*:nodegroup/${each.value.cluster_name}/${each.value.node_group_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${each.value.region}:*:log-group:/aws/lambda/eks-scheduler-${each.value.cluster_key}-${each.value.action}:*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "eks_scheduler" {
  for_each = local.workflows_map

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "eks-scheduler-${each.value.cluster_key}-${each.value.action}"
  role             = aws_iam_role.lambda_exec[each.key].arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      CLUSTER_NAME    = each.value.cluster_name
      NODE_GROUP_NAME = each.value.node_group_name
      REGION          = each.value.region
      ACTION          = each.value.action
      MIN_SIZE        = tostring(each.value.min_size)
      DESIRED_SIZE    = tostring(each.value.desired_size)
      MAX_SIZE        = tostring(each.value.max_size)
    }
  }

  tags = merge(var.tags, {
    Name        = "eks-scheduler-${each.value.cluster_key}-${each.value.action}"
    Cluster     = each.value.cluster_name
    NodeGroup   = each.value.node_group_name
    Action      = each.value.action
    Enabled     = tostring(each.value.enabled)
    ManagedBy   = "terraform"
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.workflows_map

  name              = "/aws/lambda/eks-scheduler-${each.value.cluster_key}-${each.value.action}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name      = "eks-scheduler-${each.value.cluster_key}-${each.value.action}-logs"
    Cluster   = each.value.cluster_name
    ManagedBy = "terraform"
  })
}

# EventBridge Rule for scheduling
resource "aws_cloudwatch_event_rule" "eks_scheduler" {
  for_each = local.workflows_map

  name                = "eks-scheduler-${each.value.cluster_key}-${each.value.action}"
  description         = "${title(each.value.action)} EKS node group ${each.value.node_group_name} for cluster ${each.value.cluster_name}"
  schedule_expression = each.value.cron_expression
  state               = each.value.enabled ? "ENABLED" : "DISABLED"

  tags = merge(var.tags, {
    Name        = "eks-scheduler-${each.value.cluster_key}-${each.value.action}"
    Cluster     = each.value.cluster_name
    NodeGroup   = each.value.node_group_name
    Action      = each.value.action
    ManagedBy   = "terraform"
  })
}

# EventBridge Target - Link rule to Lambda
resource "aws_cloudwatch_event_target" "eks_scheduler_target" {
  for_each = local.workflows_map

  rule      = aws_cloudwatch_event_rule.eks_scheduler[each.key].name
  target_id = "EKSSchedulerLambda"
  arn       = aws_lambda_function.eks_scheduler[each.key].arn
}

# Lambda Permission for EventBridge to invoke
resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = local.workflows_map

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eks_scheduler[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eks_scheduler[each.key].arn
}
