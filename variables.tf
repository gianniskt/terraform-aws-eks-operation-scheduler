variable "clusters" {
  description = "Map of EKS clusters with their scheduling configurations"
  type = map(object({
    cluster_name    = string
    node_group_name = string
    region          = string
    start_schedule = object({
      type   = optional(string, "weekly")
      days   = optional(list(string), [])
      week   = optional(number, null)
      day    = optional(string, null)
      hour   = number
      minute = number
    })
    stop_schedule = object({
      type   = optional(string, "weekly")
      days   = optional(list(string), [])
      week   = optional(number, null)
      day    = optional(string, null)
      hour   = number
      minute = number
    })
    min_size        = number
    desired_size    = number
    max_size        = number
    enabled_start   = optional(bool, true)
    enabled_stop    = optional(bool, true)
  }))
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
