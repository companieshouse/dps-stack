locals {
  application_subnet_ids_by_az = values(zipmap(data.aws_subnet.application.*.availability_zone, data.aws_subnet.application.*.id))

  common_tags = {
    Environment = var.environment
    Service     = var.service
  }

  common_resource_name = "${var.service}-${var.environment}"
  dns_zone             = "${var.environment}.${var.dns_zone_suffix}"

  security_s3_data            = data.vault_generic_secret.security_s3_buckets.data
  session_manager_bucket_name = local.security_s3_data.session-manager-bucket-name

  security_kms_keys_data = data.vault_generic_secret.security_kms_keys.data
  ssm_kms_key_id         = local.security_kms_keys_data.session-manager-kms-key-arn

  dps_log_groups = {
    for dps_log in var.dps_log_groups[*].name : "dps-${lower(dps_log)}" => {
      log_retention_in_days = lookup(var.dps_log_groups[index(var.dps_log_groups[*].name, dps_log)], "log_retention_in_days", var.default_log_retention_in_days)
      kms_key_id            = lookup(var.dps_log_groups[index(var.dps_log_groups[*].name, dps_log)], "kms_key_id", local.logs_kms_key_id)
      log_name              = dps_log
    }
  }

  dps_log_group_arns = [
    for log_group in merge(
      aws_cloudwatch_log_group.dps,
      { "cloudwatch" = aws_cloudwatch_log_group.cloudwatch }
    )
    : log_group.arn
  ]

  instance_profile_writable_buckets   = [local.session_manager_bucket_name]
  instance_profile_kms_key_access_ids = [local.ssm_kms_key_id]

  logs_kms_key_id = data.vault_generic_secret.kms_keys.data["logs"]
}
