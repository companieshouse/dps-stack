module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.286"
  name   = "${var.service}-profile"

  cw_log_group_arns = formatlist("%s:*", local.dps_log_group_arns)
  enable_ssm        = true
  kms_key_refs      = local.instance_profile_kms_key_access_ids
  s3_buckets_write  = local.instance_profile_writable_buckets

  custom_statements = [
    {
      sid       = "CloudWatchMetricsWrite"
      effect    = "Allow"
      resources = ["*"]
      actions = [
        "cloudwatch:PutMetricData"
      ]
    }
  ]
}
