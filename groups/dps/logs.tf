resource "aws_cloudwatch_log_group" "dps" {
  for_each = local.dps_log_groups

  name              = each.key
  retention_in_days = each.value.log_retention_in_days
  kms_key_id        = each.value.kms_key_id

  tags = merge(local.common_tags, {
    LogName = each.value.log_name
  })
}

resource "aws_cloudwatch_log_group" "cloudwatch" {
  name              = "${var.service}-cloudwatch"
  retention_in_days = var.default_log_retention_in_days
  kms_key_id        = local.logs_kms_key_id

  tags = merge(local.common_tags, {
    LogName = "cloudwatch"
  })
}
