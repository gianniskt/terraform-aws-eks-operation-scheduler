locals {
  clusters = var.clusters

  # Flatten clusters into individual workflows (start/stop actions)
  workflows = flatten([
    for cluster_key, cluster in local.clusters : [
      {
        cluster_key      = cluster_key
        action           = "start"
        schedule         = cluster.start_schedule
        enabled          = cluster.enabled_start
        cluster_name     = cluster.cluster_name
        node_group_name  = cluster.node_group_name
        region           = cluster.region
        min_size         = cluster.min_size
        desired_size     = cluster.desired_size
        max_size         = cluster.max_size
        # Convert schedule to EventBridge cron expression
        cron_expression = cluster.start_schedule.type == "monthly" ? (
          # Monthly: cron(minute hour ? month day-of-week#week *)
          # Example: 1st Monday = cron(0 8 ? * MON#1 *)
          "cron(${cluster.start_schedule.minute} ${cluster.start_schedule.hour} ? * ${upper(substr(cluster.start_schedule.day, 0, 3))}${cluster.start_schedule.week != null ? "#${cluster.start_schedule.week}" : ""} *)"
        ) : (
          # Weekly: cron(minute hour ? * day-of-week *)
          # Example: Mon-Fri = cron(0 8 ? * MON-FRI *)
          "cron(${cluster.start_schedule.minute} ${cluster.start_schedule.hour} ? * ${join(",", [for d in cluster.start_schedule.days : upper(substr(d, 0, 3))])} *)"
        )
      },
      {
        cluster_key      = cluster_key
        action           = "stop"
        schedule         = cluster.stop_schedule
        enabled          = cluster.enabled_stop
        cluster_name     = cluster.cluster_name
        node_group_name  = cluster.node_group_name
        region           = cluster.region
        min_size         = 0
        desired_size     = 0
        max_size         = 0
        # Convert schedule to EventBridge cron expression
        cron_expression = cluster.stop_schedule.type == "monthly" ? (
          "cron(${cluster.stop_schedule.minute} ${cluster.stop_schedule.hour} ? * ${upper(substr(cluster.stop_schedule.day, 0, 3))}${cluster.stop_schedule.week != null ? "#${cluster.stop_schedule.week}" : ""} *)"
        ) : (
          "cron(${cluster.stop_schedule.minute} ${cluster.stop_schedule.hour} ? * ${join(",", [for d in cluster.stop_schedule.days : upper(substr(d, 0, 3))])} *)"
        )
      }
    ]
  ])

  # Create map for for_each usage
  workflows_map = { for w in local.workflows : "${w.cluster_key}-${w.action}" => w }
}
