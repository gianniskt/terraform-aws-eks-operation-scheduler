terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Example: Single EKS cluster with weekly scheduling
module "eks_operation_scheduler" {
  source  = "gianniskt/eks-operation-scheduler/aws"
  version = "~> 1.0"

  clusters = {
    dev-cluster = {
      cluster_name    = "my-eks-dev-cluster"
      node_group_name = "my-node-group"
      region          = "us-east-1"

      # Start weekdays at 8 AM UTC
      start_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 8
        minute = 0
      }

      # Stop weekdays at 6 PM UTC
      stop_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 18
        minute = 0
      }

      # Node group sizing when started
      min_size     = 1
      desired_size = 2
      max_size     = 5

      # Enable both start and stop schedules
      enabled_start = true
      enabled_stop  = true
    }
  }

  tags = {
    Environment = "dev"
    Project     = "eks-scheduler-demo"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "lambda_functions" {
  description = "Created Lambda functions"
  value       = module.eks_scheduler.lambda_function_names
}

output "eventbridge_rules" {
  description = "Created EventBridge rules"
  value       = module.eks_scheduler.eventbridge_rule_names
}

output "schedules" {
  description = "Workflow schedules"
  value       = module.eks_scheduler.workflow_schedules
}
