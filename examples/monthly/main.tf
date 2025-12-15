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

# Example: Monthly scheduling patterns
module "eks_operation_scheduler" {
  source  = "gianniskt/eks-operation-scheduler/aws"
  version = "~> 1.0"

  clusters = {
    # Cluster runs on 1st Monday of each month
    monthly-cluster-1 = {
      cluster_name    = "eks-monthly-demo"
      node_group_name = "monthly-nodes"
      region          = "us-east-1"

      # Start on 1st Monday at 8 AM
      start_schedule = {
        type   = "monthly"
        week   = 1  # 1st occurrence
        day    = "Monday"
        hour   = 8
        minute = 0
      }

      # Stop on 1st Monday at 6 PM
      stop_schedule = {
        type   = "monthly"
        week   = 1  # 1st occurrence
        day    = "Monday"
        hour   = 18
        minute = 0
      }

      min_size     = 1
      desired_size = 2
      max_size     = 3

      enabled_start = true
      enabled_stop  = true
    }

    # Cluster runs on 2nd and 4th Wednesday
    monthly-cluster-2 = {
      cluster_name    = "eks-bi-weekly"
      node_group_name = "bi-weekly-nodes"
      region          = "us-east-1"

      # Start on 2nd Wednesday at 9 AM
      start_schedule = {
        type   = "monthly"
        week   = 2  # 2nd occurrence
        day    = "Wednesday"
        hour   = 9
        minute = 0
      }

      # Stop on 2nd Wednesday at 5 PM
      stop_schedule = {
        type   = "monthly"
        week   = 2  # 2nd occurrence
        day    = "Wednesday"
        hour   = 17
        minute = 0
      }

      min_size     = 1
      desired_size = 1
      max_size     = 2

      enabled_start = true
      enabled_stop  = true
    }
  }

  tags = {
    Environment = "monthly-demo"
    Project     = "eks-scheduler"
    ManagedBy   = "terraform"
  }
}

output "monthly_schedules" {
  description = "Monthly schedule configurations"
  value       = module.eks_scheduler.workflow_schedules
}

output "cron_expressions" {
  description = "Generated EventBridge cron expressions"
  value = {
    for k, v in module.eks_scheduler.workflow_schedules : k => v.cron_expression
  }
}
