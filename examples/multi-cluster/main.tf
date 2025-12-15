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

# Example: Multiple EKS clusters with different schedules
module "eks_operation_scheduler" {
  source  = "gianniskt/eks-operation-scheduler/aws"
  version = "~> 1.0"

  clusters = {
    # Development cluster - stops on weekends and nights
    dev-cluster = {
      cluster_name    = "eks-dev"
      node_group_name = "dev-nodes"
      region          = "us-east-1"

      start_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 8
        minute = 0
      }

      stop_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 18
        minute = 0
      }

      min_size     = 1
      desired_size = 2
      max_size     = 3

      enabled_start = true
      enabled_stop  = true
    }

    # Staging cluster - similar to dev but different times
    staging-cluster = {
      cluster_name    = "eks-staging"
      node_group_name = "staging-nodes"
      region          = "us-east-1"

      start_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 7
        minute = 30
      }

      stop_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 20
        minute = 0
      }

      min_size     = 2
      desired_size = 3
      max_size     = 5

      enabled_start = true
      enabled_stop  = true
    }

    # Test cluster - only runs during business hours
    test-cluster = {
      cluster_name    = "eks-test"
      node_group_name = "test-nodes"
      region          = "us-west-2"

      start_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 9
        minute = 0
      }

      stop_schedule = {
        type   = "weekly"
        days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hour   = 17
        minute = 0
      }

      min_size     = 1
      desired_size = 1
      max_size     = 2

      enabled_start = true
      enabled_stop  = true
    }

    # Demo cluster - temporarily disabled for maintenance
    demo-cluster = {
      cluster_name    = "eks-demo"
      node_group_name = "demo-nodes"
      region          = "us-east-1"

      start_schedule = {
        type   = "weekly"
        days   = ["Monday", "Wednesday", "Friday"]
        hour   = 10
        minute = 0
      }

      stop_schedule = {
        type   = "weekly"
        days   = ["Monday", "Wednesday", "Friday"]
        hour   = 16
        minute = 0
      }

      min_size     = 1
      desired_size = 1
      max_size     = 2

      # Temporarily disabled
      enabled_start = false
      enabled_stop  = false
    }
  }

  tags = {
    Environment = "multi"
    Project     = "eks-scheduler"
    ManagedBy   = "terraform"
  }
}

# Outputs grouped by cluster
output "dev_cluster_functions" {
  description = "Lambda functions for dev cluster"
  value = {
    start = module.eks_scheduler.lambda_function_names["dev-cluster-start"]
    stop  = module.eks_scheduler.lambda_function_names["dev-cluster-stop"]
  }
}

output "staging_cluster_functions" {
  description = "Lambda functions for staging cluster"
  value = {
    start = module.eks_scheduler.lambda_function_names["staging-cluster-start"]
    stop  = module.eks_scheduler.lambda_function_names["staging-cluster-stop"]
  }
}

output "all_schedules" {
  description = "All configured schedules"
  value       = module.eks_scheduler.workflow_schedules
}
