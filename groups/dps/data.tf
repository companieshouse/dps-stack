data "aws_ami" "dps" {
  owners      = [var.ami_owner_id]
  most_recent = true
  name_regex  = "^${var.service}-ami-\\d.\\d.\\d"

  filter {
    name   = "name"
    values = ["${var.service}-ami-${var.ami_version_pattern}"]
  }
}

data "aws_ec2_managed_prefix_list" "shared_services_management" {
  name = "shared-services-management-cidrs"
}

data "aws_subnet" "application" {
  count = length(data.aws_subnets.application.ids)
  id    = tolist(data.aws_subnets.application.ids)[count.index]
}

data "aws_subnets" "application" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.heritage.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.application_subnet_pattern]
  }
}

data "aws_vpc" "heritage" {
  filter {
    name   = "tag:Name"
    values = ["vpc-heritage-${var.environment}"]
  }
}

data "cloudinit_config" "config" {
  count = var.instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud-init/templates/system-config.yml.tpl", {})
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/bootstrap-commands.yml.tpl", {
      instance_hostname = "${var.service}-${var.environment}-${count.index + 1}"
      lvm_block_devices = var.lvm_block_devices
    })
  }
}

data "aws_route53_zone" "dps" {
  name   = local.dns_zone
  vpc_id = data.aws_vpc.heritage.id
}

data "vault_generic_secret" "kms_keys" {
  path = "aws-accounts/${var.aws_account}/kms"
}

data "vault_generic_secret" "security_kms_keys" {
  path = "aws-accounts/security/kms"
}

data "vault_generic_secret" "security_s3_buckets" {
  path = "aws-accounts/security/s3"
}


